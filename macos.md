# RPATH under macosx
最佳实践：
1、所有的动态库rpath都设置为@rpath
2、可执行文件的rpath设为其所要查找的目录，比如@loader_path;@loader_path/../Frameworks
```
set_target_properties(${TARGET_NAME} PROPERTIES
  BUILD_WITH_INSTALL_RPATH ON
  INSTALL_RPATH "@loader_path;@loader_path/../lib"
)
```

