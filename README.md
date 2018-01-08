# typewriter

<div align=center>
	![logo](https://github.com/typwr/typewriter/blob/master/Assets/logo.png)
</div>

简单来说，typewriter是客户端翻译服务端数据交换格式的代码翻译器。

当在架设到不同机器上的系统之间交换数据时，往往要有一套特殊的数据交换格式或者协议来作为中间人，比较典型的就是JSON和ProtocolBuffer。而把中间数据格式转换为系统中的数据，是一段繁琐的、无趣的编程过程，这个过程实际上，就是将中间数据格式进行语法翻译，翻译成系统中对应语言的代码。

typewriter就是上述问题在客户端领域的翻译器。



#### [尝尝鲜(Example)](https://github.com/typwr/typewriter-Example)



## 支持

typewriter支持主流的语言和数据交换格式，见下表：

| 语言    | JSON          | ProtocolBuffer |
| ----- | ------------- | -------------- |
| ObjC  | ✅（自由选择学序列化方案） | ✅              |
| Swift | ✅（Codable）    | ❎              |
| Java  | ✅（自由选择序列化方案）  | ✅（Wire）        |



## 场景

客户端将从服务端拿到的数据常做为Model，这就是自然使typewriter称为构建应用Model Layer的好帮手。很可惜的是，无论怎么抽象，typewriter也不能覆盖100%的场景。假如，数据需要有大量的处理逻辑，typewriter也就无能为力了。不过，在90%的情况下，typewriter是可以胜任的。不仅如此，在一些架构特点下，typewriter能发挥出更多的威力。

架构特点：

- 业务后移：在客户端/服务端之间，服务端承担更多的数据处理、计算责任，尽量留给客户端只做展示，甚至发展出bff(backend for frontend)。
- 数据交换格式隐藏：客户端网络层或中间处理层，无论何种数据交换格式，最终生成对象交给调用方，在RPC中比较常见。
- 业务一致：iOS和android双端保证呈现出来的业务一致性。
- 字节计较的代码空间(code size)：代码空间是个让客户端开发者常常头疼的问题，尤其在iOS端。
- Immutable Model Layer：客户端将Model Immutable化，结合单向数据流，形成响应式架构。



## 安装

请先确认已经安装Xcode。

#### Homebrew

```c
brew tap typwr/typewriter
brew install typewriter
```



## CLI

typewriter支持命令行使用，参数名和规则类似ProtocolBuffer的protoc，以此顺序键入：

```c
$ typewriter file1 file2 ... [options]
```

先键入输入文件，再键入输出目录，路径可以直接键入绝对路径，或者键入

```c
./
```

以作为当前目录补全。

可选的选项如下：

- --objc_out：翻译成ObjC语言的目录。
- --swift_out：翻译成Swift语言的目录。
- --java_out：翻译成Java语言的目录。
- --no_recursive：默认的翻译策略是加载所有引用到的文件，这个选项可以用来禁止。
- --help：帮助选项。



#### [更多用法-语法和规则](https://github.com/typwr/typewriter/blob/master/Docs/SyntaxAndRule.md)



## 原则

在typewriter的制作过程中，有些原则从头贯彻到尾：

- 不妄将功能做“全”、做“杂”，若学习一个翻译器的成本远大于学习语言本身，翻译器就毫无价值。
- 生成clean和compact的代码，把code size放在第一位。在表述力和代码量的权衡中，选择代码量。



## runtime

为了最大程度的复用代码，typewriter假设一些方法在Model的继承体中已经实现了。typewriter也提供了BaseModel的实现，这些代码可被视作typewriter的runtime库。可在[typewriter-Example](https://github.com/typwr/typewriter-Example)中找到。

虽然typewriter全面减少了开发者的工作量。但是为了通用化的考虑，单个框架的注解等特殊要求就需要开发者手动添加了。



#### [深入更多-BehindTheScene](https://github.com/typwr/typewriter/blob/master/Docs/BehindTheScene.md)



## Contributing

欢迎一起共建typewriter。



## License

MIT License