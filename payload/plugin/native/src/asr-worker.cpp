#include <transcribe.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <chrono>
int main(int argc,char**argv){
 if(argc!=2)return 2;
 transcribe_model_load_params lp;transcribe_model_load_params_init(&lp);
 transcribe_model *m=nullptr;auto st=transcribe_model_load_file(argv[1],&lp,&m);if(st!=TRANSCRIBE_OK)return 3;
 transcribe_session_params sp;transcribe_session_params_init(&sp);sp.n_threads=4;
 transcribe_session *s=nullptr;if(transcribe_session_init(m,&sp,&s)!=TRANSCRIBE_OK)return 4;
 std::cout<<"READY"<<std::endl;
 std::string path;
 while(std::getline(std::cin,path)){
  if(path=="QUIT")break;
  std::ifstream in(path,std::ios::binary|std::ios::ate);if(!in){std::cout<<"ERROR"<<std::endl;continue;}
  auto n=in.tellg();if(n<=0||n>16000*30*4||n%4){std::cout<<"ERROR"<<std::endl;continue;}
  std::vector<float> pcm(size_t(n)/4);in.seekg(0);in.read((char*)pcm.data(),n);
  transcribe_run_params rp;transcribe_run_params_init(&rp);rp.language="ru";
  auto t=std::chrono::steady_clock::now();st=transcribe_run(s,pcm.data(),pcm.size(),&rp);
  std::string text=st==TRANSCRIBE_OK?transcribe_full_text(s):"";
  for(char&c:text)if(c=='\n'||c=='\r')c=' ';
  std::cout<<(st==TRANSCRIBE_OK?"TEXT ":"ERROR ")<<text<<std::endl;
 }
 transcribe_session_free(s);transcribe_model_free(m);return 0;
}
