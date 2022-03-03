# Notes on C++ Templates 2nd
## automatic type conversion is not considered for deduced template parameters  
`max('a', 1.5);` won't match `tepmplate<typename T> auto max(T t1, T t2);`
