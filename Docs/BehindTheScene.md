## Behind the scene

文章中多次提到Typewriter是一个翻译器。Typewriter从架构上要支持多种数据交换格式，支持多种语言或者说跨平台。这样的翻译器是一个典型的语言应用。

而语言应用的经典piepline：

```swift
Input -> Parser -> IR -> IR.deduce -> CodeGenerator -> Output
```

Typewriter就是这样的架构，输入交给Parser后，Parser负责解析Typewriter定义的语法、语义，然后组织成数据结构IR。IR作为分离翻译器前端和翻译器后端的重要一层，还负责Typewriter的Logic，大部分的对输入信息的处理、生成哪些代码的逻辑都在IR自我推断这一步进行。经过自我推断的完备IR，交由CodeGenerator，CodeGenerator进行语言相关的代码生成。



#### Parser

Parser是多种语言的解析器。输入源可分为两种：

1. 描述JSON数据交换格式。
2. 描述GPPL(General-purpose programming language)数据交换格式。

第一种，描述JSON数据交换格式，要求文件就是JSON数据。实际上，就是将JSON作为语法媒介，将平台的JSONSerialization作为Lexer。

第二种，描述GPPL数据交换格式，要求就是通用语言文件。实际上，因为只在乎原通用语言文件中的名称、成员变量，所以就是解析通用语言的非常小的子集，不需构造复杂的Lexer。在多种通用语言的架构下，设计上选择了Builder。

值得一提的是，Parser大部分代码从以下三个维度解析Typewriter定义的语法：

- Lexer(核心语法)：抽象核心语法，类似Java中Annotation的语法，包括Expansion(展开)、OneToOne(一对一)、OneToMany(一对多)。
- Annotation(注解)：抽象平台，包括不同语言中读取Typewriter语法的形式。
- Rule(规则语法)：抽象Typewriter提供的规则，设计上使用Interpreter。



#### IR

IR是抽象输入数据交换格式后的数据结构。它也负责推断Typewriter定义的语法，确定最终生成的成员变量、方法。不同的输入采用不同的Strategy。

值得一提的是，IR内部还抽象了Analyzer，负责分析与定义的语法无关的Logic。比如，用Trie构成遵从Swift Codable需要的CodingKeys Enum和相应方法。



#### CodeGenerator

CodeGenerator是真正发生生成代码的地方，这里有个潜在的问题，解决了这个问题一切也就引刃而解了。那就是如何抽象一个语言的子集？解决这个问题就依靠以下两点理论基础：

1. 语言从构成来讲，是由简单元素构成复合元素再构成更复杂元素而组合出来的。
2. Clang将语言元素分为三类：Type、Decl、Stmt，而光生成语言，只需要Decl和Stmt就足够了。

通过这两点就可以抽象出语言的子集，然后生成代码调用这个抽象出来的子集就可以了。支持一种语言就要编写该语言的抽象子集。

有一点值得提的就是，在CodeGenerator内部需要再抽象一层FileRepresent。因为不同的语言有不同的编译单位，FileRepresent抽象掉这点，也就是代表最终的文件。比如，ObjC分为.h和.m，而Swift不区分。

整个CodeGenerator的piepline就是将语言元素装入FileRepresent。

