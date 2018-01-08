## 语法和规则

为了解析数据结构和提供强大的功能，Typewriter自定义了一个语法和规则集。



#### Rule

以下是现阶段的规则：

| 规则                    | 语法        | 含义                                       |
| --------------------- | --------- | ---------------------------------------- |
| generate              | OneToOne  | 生成的主体及其文件名。                              |
| inherit               | OneToOne  | 如果生成的主体是类，则为其继承体的名称。                     |
| implement             | OneToMany | 生成的主体实现的Protocol或Interface。              |
| commentOut            | Expansion | 生成的文件默认保留成员变量注释，这个规则则为指明丢弃。              |
| immutable             | Expansion | 生成的主体为Immutable，即其不可变，要改变使用Builder等可变版本。 |
| constructOnly         | Expansion | 生成的主体为仅创建，即其生成后便不可变。                     |
| unidirectionDataflow  | Expansion | 生成的主体融合单向数据流，即其生成后会调用方法，以供push出去。选择Immutable后，则包含该规则。 |
| specialIncludeSuffix  | OneToOne  | 生成的文件特殊的后缀，用来应对pbobjc.h等情况。              |
| initializerPreprocess | Expansion | 生成的主体初始化方法包含预处理方法，用来处理原数据。               |
| filter                | OneToMany | 过滤生成的主体的成员变量，按命名完全匹配。                    |
| predicateFilter       | OneToOne  | 过滤生成的主体的成员变量，按命名表达式匹配，按照[NSPredicate](http://nshipster.cn/nspredicate/)表达式。 |
| rewritten             | OneToMany | 重写原数据的名字和类型。                             |



#### JSON语法

对于JSON数据交换格式，要求解析的文件内容为JSON对象，文件以.json结尾。将关键字作为JSON对象的Key即可。
以下是现阶段的关键字：

| 关键字            | 格式     | 含义                                       |
| -------------- | ------ | ---------------------------------------- |
| generate       | String | 同generate规则。                             |
| inherit        | String | 同inherit规则。                              |
| implement      | Array  | 同implement规则，可多个元素。                      |
| options        | Array  | 多条可选规则，可选范围为constructOnly、 immutable、 initializerPreprocess、 unidirectionDataflow。 |
| memberVariable | Map    | 生成主体成员变量Map对象。                           |
| type           | String | 成员变量类型。                                  |
| nullable       | String | 成员变量可空性，可选范围为required、 almost、 optional。 |
| rewrittenType  | String | 成员变量重写前的类型。                              |
| rewrittenName  | String | 成员变量重写前的名字。                              |
| flatten        | String | 成员变量进行扁平化操作的路径，以.分隔。                     |
| annotation     | String | 成员变量的注解，以&&分隔。                           |



#### MemberVariable

大部分关键字直接作为Key即可，而成员变量作为整个翻译过程的主角，也有较多的关键字，下面是一个PhoneBrand类型的brand成员变量：

```json
"brand" : {
	 "type" : "PhoneBrand",
  	 "nullable" : "required",
     "flatten" : "equipment.info"
     "annotation" : "@JSONField(name = \"phoneBrand\")&&@CustomAnnotation"
},
```

可以看到brand还经过了扁平化操作，这是解决变量在JSON中嵌套过深的特性，将其可视化便是将该结构

```json
{
	"equipment" : {
		"info" : {
			"phoneBrand" : ...
      	}
	}
}
```

扁平化为该结构

```json
{
	"brand" : ...
}
```

除此之外，还给成员变量添加了两个注解，当然只有在支持注解的语言中才会生效。



#### GPPL语法

对于GPPL(General-purpose programming language)交换格式，要求解析的文件内容为GPPL语言文件。将规则，按定义的语法形式在原文件标注上即可，其语法格式类似Java的Annotation。

在ObjC中：

```objective-c
#pragma Typewriter(...)
```

并且注意单个规则内部换行要用\。

在Java中：

```java
@Typewriter(...)
```

为了兼容Java8以下版本，多个规则要嵌套repeatable：

```java
@RepeatableTypewriter({
        @Typewriter(...),
        @Typewriter(...),
        ...
})
```

规则的语法也不复杂，包含三种，Expansion、OneToOne和OneToMany。Expansion代表展开，也就是规则本身，OneToOne代表就是一对一，除了规则，还有一个对应主体，而OneToMany有对个对应主体。

Expansion：

```java
key
```

OneToOne：

```java
key=value
```

OneToMany：

```java
key={value1,value2,...}
```



#### 类型

Typewriter有自己的类型系统，无论是输入或是输出都在此类型系统中：

- Float
- Double
- Uint32
- Uint64
- Sint32
- Sint64
- Bool
- String
- Array
- Map
- Date
- Any
- Ambiguous

大部分类型都可以望名生意，而Ambiguous代表模糊类型，即Typewriter不需要理解的类型，包括Class、Struct、Enum、Protocol、Interface等。



#### Rewritten

大部分规则直接按照语法写就可以，而rewritten有自己的语法，在GPPL中如下：

| 规则   | 语法       | 意义        |
| ---- | -------- | --------- |
| on   | OneToOne | 重写的成员变量名。 |
| name | OneToOne | 重写的名称。    |
| type | OneToOne | 重写的类型。    |

比如，将成员变量educationEnum，名字重写为education，并将其类型重写为EducationLevel：

```java
@Typewriter(rewritten={@Rewritten(on=educationEnum,name=education,type=EducationLevel),
					 ...})
```

在JSON中关键字为rewrittenName和rewrittenType，同样的重写如下：

```json
"education" : {
	"type" : "EducationLevel",
     "rewrittenName" : "educationEnum",
     "rewrittenType" : "String"
 }
```

然而并不是所有类型都可以重写，重写的类型会有限制，以下四种包含了大部分的场景：

- String：可重写为Float、Double、Uint32、Uint64、Sint32、Sint64、Bool、Ambiguous，其中Ambiguous比较特殊，String重写为Ambiguous实际上就是将String重写为Enum。
- Ambiguous：可重写为Ambiguous。
- Any：可重写为Ambiguous。
- Array：可重写其Element。
- Map：可重写其Value类型。

特别的一点：重写的类型可以引用其他需要解析的文件，用

```c
$ref(...)
```

包裹住就可以，其他引用文件都认为在原文件目录下。



#### 特别注意

以下特殊case请注意：

- GPPL交换格式中可有成员变量重写为JSON交换格式，但反之则不处理。

