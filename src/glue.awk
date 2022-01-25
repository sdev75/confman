function recurse(file){
  while ((getline line<file) > 0)
    if (line ~/^#include/){
      gsub(/^#include /,"",line)
      recurse(ENVIRON["PWD"] "/src/" line)
    } else {
      print line 
    }
    
  close(file)
}
{ 
  recurse(FILENAME)
  exit
}
