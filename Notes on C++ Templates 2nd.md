# Notes on C++ Templates 2nd
## automatic type conversion is not considered for deduced template parameters  
`max('a', 1.5);` won't match `tepmplate<typename T> auto max(T t1, T t2);`

## implementation of member funciton of a class template
```
// if implementation is outside class, it should look like this
template <typename T>
void Stack<T>::push (const T& elem){
  // do something
}

// or just implement it inline
template<typename T>
class Stack {
  void push(const T& elem){
    // do something
  }
}
```

## functions which are not called in a class template will not be instantiated
So you can use part of a class template, it saves space and time.
It is OK that the template argument doesn't fit in everyting, if you dont use the unfitted ones.

