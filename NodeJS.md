## VSCode launch setting of debugging node addon through mocha test
```
{
    "name": "msvc launch",
    "type": "cppvsdbg",
    "request": "launch",
    "program": "node",
    "args": [
        "${workspaceFolder}/node_modules/mocha/bin/mocha",
        "${workspaceFolder}/test/test_all.js",
        "-slow",
        "200",
        "-timeout",
        "5000"
    ],
    "cwd": "${workspaceFolder}",
    "console": "integratedTerminal"
},
```
