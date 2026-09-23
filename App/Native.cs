using System;
using System.IO;
using System.Net;
using System.Text;
using System.Threading;
using System.Diagnostics;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace Cofre {
 public static class Native {
  [DllImport("winsqlite3.dll", CallingConvention=CallingConvention.Cdecl)] static extern int sqlite3_open_v2(byte[] n, out IntPtr db, int flags, IntPtr vfs);
  [DllImport("winsqlite3.dll", CallingConvention=CallingConvention.Cdecl)] static extern int sqlite3_close(IntPtr db);
  [DllImport("winsqlite3.dll", CallingConvention=CallingConvention.Cdecl)] static extern IntPtr sqlite3_errmsg(IntPtr db);
  [DllImport("winsqlite3.dll", CallingConvention=CallingConvention.Cdecl)] static extern IntPtr sqlite3_backup_init(IntPtr dest, byte[] dn, IntPtr src, byte[] sn);
  [DllImport("winsqlite3.dll", CallingConvention=CallingConvention.Cdecl)] static extern int sqlite3_backup_step(IntPtr backup, int pages);
  [DllImport("winsqlite3.dll", CallingConvention=CallingConvention.Cdecl)] static extern int sqlite3_backup_finish(IntPtr backup);
  [DllImport("winsqlite3.dll", CallingConvention=CallingConvention.Cdecl)] static extern int sqlite3_prepare_v2(IntPtr db, byte[] sql, int len, out IntPtr stmt, IntPtr tail);
  [DllImport("winsqlite3.dll", CallingConvention=CallingConvention.Cdecl)] static extern int sqlite3_step(IntPtr stmt);
  [DllImport("winsqlite3.dll", CallingConvention=CallingConvention.Cdecl)] static extern IntPtr sqlite3_column_text(IntPtr stmt, int col);
  [DllImport("winsqlite3.dll", CallingConvention=CallingConvention.Cdecl)] static extern int sqlite3_finalize(IntPtr stmt);
  static byte[] Z(string s) {return Encoding.UTF8.GetBytes(s+"\0");}
  static string U(IntPtr p) {if(p==IntPtr.Zero)return "";int n=0;while(Marshal.ReadByte(p,n)!=0)n++;byte[] b=new byte[n];Marshal.Copy(p,b,0,n);return Encoding.UTF8.GetString(b);}
  static IntPtr Open(string path,int flags) {
   IntPtr db;int rc=sqlite3_open_v2(Z(path),out db,flags,IntPtr.Zero);
   if(rc!=0){string m=U(sqlite3_errmsg(db));if(db!=IntPtr.Zero)sqlite3_close(db);throw new IOException("SQLite: "+m);}
   return db;
  }
  public static string Scalar(string path,string sql) {
   IntPtr db=Open(path,1),stmt=IntPtr.Zero;
   try {if(sqlite3_prepare_v2(db,Z(sql),-1,out stmt,IntPtr.Zero)!=0)throw new IOException(U(sqlite3_errmsg(db)));
    int rc=sqlite3_step(stmt);if(rc==101)return "";if(rc!=100)throw new IOException(U(sqlite3_errmsg(db)));return U(sqlite3_column_text(stmt,0));
   } finally {if(stmt!=IntPtr.Zero)sqlite3_finalize(stmt);sqlite3_close(db);}
  }
  public static void Backup(string source,string destination) {
   if(File.Exists(destination))throw new IOException("Destino já existe.");
   IntPtr src=IntPtr.Zero,dst=IntPtr.Zero,bk=IntPtr.Zero;
   try {src=Open(source,1);dst=Open(destination,6);bk=sqlite3_backup_init(dst,Z("main"),src,Z("main"));
    if(bk==IntPtr.Zero)throw new IOException(U(sqlite3_errmsg(dst)));
    Stopwatch timer=Stopwatch.StartNew();int rc;
    do {rc=sqlite3_backup_step(bk,512);if(rc==5||rc==6)Thread.Sleep(100);if(timer.Elapsed.TotalSeconds>90)throw new IOException("Banco ocupado por mais de 90 segundos.");}while(rc==0||rc==5||rc==6);
    if(rc!=101)throw new IOException("Falha de snapshot SQLite: "+rc);
    int end=sqlite3_backup_finish(bk);bk=IntPtr.Zero;if(end!=0)throw new IOException("Falha ao finalizar SQLite: "+end);
   } finally {if(bk!=IntPtr.Zero)sqlite3_backup_finish(bk);if(dst!=IntPtr.Zero)sqlite3_close(dst);if(src!=IntPtr.Zero)sqlite3_close(src);}
   if(Scalar(destination,"PRAGMA quick_check")!="ok")throw new IOException("A cópia SQLite falhou no quick_check.");
  }
  // Connect server streaming: lê apenas o primeiro estado, com limite e timeout.
  public static string Rpc(int port,string token,string method,string json,bool stream) {
   if(port<1||port>65535||!System.Text.RegularExpressions.Regex.IsMatch(method,"^[A-Za-z]+$"))throw new ArgumentException("Endpoint inválido.");
   var req=(HttpWebRequest)WebRequest.Create("http://127.0.0.1:"+port+"/exa.language_server_pb.LanguageServerService/"+method);
   req.Proxy=null;req.Method="POST";req.Timeout=120000;req.ReadWriteTimeout=120000;req.AllowAutoRedirect=false;
   req.Headers["X-Codeium-Csrf-Token"]=token;req.Headers["Connect-Protocol-Version"]="1";
   req.ContentType=stream?"application/connect+json":"application/json";
   byte[] body=Encoding.UTF8.GetBytes(json);
   if(stream){byte[] frame=new byte[body.Length+5];frame[1]=(byte)(body.Length>>24);frame[2]=(byte)(body.Length>>16);frame[3]=(byte)(body.Length>>8);frame[4]=(byte)body.Length;Array.Copy(body,0,frame,5,body.Length);body=frame;}
   req.ContentLength=body.Length;
   using(var s=req.GetRequestStream())s.Write(body,0,body.Length);
   using(var response=(HttpWebResponse)req.GetResponse())using(var s=response.GetResponseStream()){
    if(!stream)using(var r=new StreamReader(s,Encoding.UTF8))return r.ReadToEnd();
    byte[] header=Exact(s,5);int n=(header[1]<<24)|(header[2]<<16)|(header[3]<<8)|header[4];
    if(header[0]!=0||n<0||n>67108864)throw new IOException("Resposta Connect incompatível.");
    return Encoding.UTF8.GetString(Exact(s,n));
   }
  }
  static byte[] Exact(Stream s,int n){byte[] b=new byte[n];int p=0,k;while(p<n){k=s.Read(b,p,n-p);if(k==0)throw new EndOfStreamException();p+=k;}return b;}
  static ulong Var(byte[] b,ref int p,int end){ulong v=0;for(int shift=0;shift<64;shift+=7){if(p>=end)throw new InvalidDataException("Protobuf truncado.");byte x=b[p++];v|=(ulong)(x&127)<<shift;if((x&128)==0)return v;}throw new InvalidDataException("Varint inválido.");}
  static int Length(byte[] b,ref int p,int end){ulong n=Var(b,ref p,end);if(n>(ulong)(end-p))throw new InvalidDataException("Protobuf truncado.");return (int)n;}
  static void Skip(byte[] b,ref int p,int end,int wire){int n;switch(wire){case 0:Var(b,ref p,end);return;case 1:n=8;break;case 2:n=Length(b,ref p,end);break;case 5:n=4;break;default:throw new InvalidDataException("Wire type não suportado.");}if(n>end-p)throw new InvalidDataException("Protobuf truncado.");p+=n;}
  public static string[] SummaryIds(string path){byte[] b=File.ReadAllBytes(path);int p=0;var ids=new HashSet<string>(StringComparer.OrdinalIgnoreCase);
   while(p<b.Length){ulong tag=Var(b,ref p,b.Length);if(tag!=10){Skip(b,ref p,b.Length,(int)(tag&7));continue;}int n=Length(b,ref p,b.Length),end=p+n;string id=null;bool value=false;
    while(p<end){tag=Var(b,ref p,end);if(tag==10){n=Length(b,ref p,end);id=Encoding.UTF8.GetString(b,p,n);p+=n;}else if(tag==18){n=Length(b,ref p,end);p+=n;value=true;}else Skip(b,ref p,end,(int)(tag&7));}
    Guid parsed;if(!value||!Guid.TryParse(id,out parsed)||!ids.Add(id))throw new InvalidDataException("Mapa de summaries não reconhecido.");
   }var result=new string[ids.Count];ids.CopyTo(result);return result;
  }
 }
}
