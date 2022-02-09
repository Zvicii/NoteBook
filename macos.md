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

# Codesign  
1、首先需要一份developer id证书  
2、codesign -o runtime -f -s "cert name" -v ${_install_excutable_path} --deep  

若cmake generator为xcode则无需显式调用codesign, 如果生成的是bundle则需要加上--deep参数  
```
set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
        XCODE_ATTRIBUTE_OTHER_CODE_SIGN_FLAGS "--deep"
    )
```

