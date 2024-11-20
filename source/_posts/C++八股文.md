---
title: Hello World
date: 2024-11-20 00:41:31
update: 2024-11-20 00:41:49
categories:
	-general
toc: true
---

## c++ 新特性

尾置返回值

std::optional

结构化绑定

## STL

#### RAII 是什么？

resource acquire is initialization 资源获取即初始化

将资源和对象的生命周期绑定。



#### hash map 怎么实现

![img](http://oss.interviewguide.cn/img/202205220035271.png)



标准库用 vector 保存链表的头指针

什么时候 rehash ？ 

超过最大负载因子



#### vector 扩容机制

两倍或者 1.5 倍。

均摊分析



#### 容器删除和迭代器

* 顺序容器 (vector deque)
  * erase 迭代器不仅会使该迭代器失效，还会使后面的迭代器都失效。
  * 但是 erase 会返回下一个有效的迭代器。
* 关联容器 (map, set, multimap, multiset)
  * erase 迭代器只是让该迭代器失效。
  * erase 返回 void。
  * 使用 earse(it++) 的方法删除迭代器。



#### 迭代器的类型

前向

* unordered_set & unordered_map
* forward_list

双向

* list
* set / map

随机访问

* deque
* vector

**输入迭代器** InputIterator 支持逐个遍历和读取

**输出迭代器** OutputIterator  支持逐个遍历和写入



#### 迭代器失效

以 vector 为例

插入位置之后的迭代器失效。如果插入使得需要扩容时，所有迭代器失效。

删除位置之后的迭代器失效。



rehash 之后 unordered_map 的迭代器失效





#### List 和 deque 的区别

list 是一个双向环形链表

deque 是一个双向开口的连续线性空间

deque 和 vector

* deque 允许常数时间对头部和尾部插入或者移除
* deque **没有容量概念**。动态地以分段连续空间组合而成。没有所谓的空间保留功能？
* deque 支持随机访问



空间配置器 allocator deallocator

两级配置器

![img](http://oss.interviewguide.cn/img/202205220035104.png)

![img](https://img2022.cnblogs.com/blog/741401/202205/741401-20220504160717545-639927952.png)

* 第一级直接用 malloc， free 和 relloc
* 第二级若区块小于 128 bytes 使用内存池
  * free_list 是一个以 8 为容量公差的长度为 16 的链表，最后一个节点区块为 128 bytes。
  * 不足时调用 refill 申请 [1, 20] 块，并且将多的块放入 freelist
  * 内存池一个 njob 空间都不够的时候，用 malloc 向 OS 申请内存
    * 申请不到，在后续的  freelist 里找
    * 还是找不到，转到一级适配器，借助 oom 机制申请内存。
* deallocate 先判断大小，若大于 128b 调用一级配置器，否则调用二级配置器。



#### std::deque 的实现

问题：vector 头部操作的效率特别差

```c++
class deque
{
    ...
protected:
    typedef pointer* map_pointer;//指向map指针的指针
    map_pointer map;//指向map
    size_type map_size;//map的大小
public:
    ...
    iterator begin();
    iterator end();
    ...
}

// deque 迭代器维护连续的假象，迭代器需要知道:
// 1. 自己是不是在缓冲区边缘
// 2. 是不是在对头？上一个、下一个缓冲区在哪里？
// 3. 因此，deque 迭代器，需要保存：
// 		* first 缓冲区第一个元素		// 判断是不是第一个元素
// 		* last 缓冲区最后一个元素的后面		// 判断后面还有没有元素
// 		* 当前元素的指针
// 		* map_node 的指针
// 		* buffer_size 缓冲区能放的元素大小
// 迭代器存四个变量
// 一个是
template<class T,...>
struct __deque_iterator{
    size_t buffer_size();
    ...
    T* cur;
    T* first;
    T* last;
    map_pointer node;//map_pointer 等价于 T**
}
```



## 基础语法

#### noexcept

将函数标记为不会抛出异常，使用noexcept关键字标记的函数在它抛出异常时，编译器会直接调用名为"std::terminate"的方法，来**中断**程序的执行。

析构函数通常会被默认加上 noexcept

* 希望析构直接完成
* 或者程序终止



移动的时候加上 noexcept

* 大多数容器调整大小用的**不会抛出异常的移动构造**，否则调用拷贝构造
  * 因为在资源的移动过程中如果抛出了异常，那么那些正在被处理的**原始对象数据**可能因为异常而丢失
  * 拷贝的时候原始数据是安全的

#### 指针和引用的区别

指针是变量，存一个地址。引用是一个别名。

指针在传参的时候是值传递，引用是引用传递。

引用必须初始化，指针可以为空，也可以随便指向一个地址。

引用不可以再改变。引用不能为空。

递归的时候用引用可以降低开销。



#### define const typedef inline

1. define 只在预处理阶段起作用，没有类型检查。展开后占用的是代码段空间。
2. const 有类型。
3. typedef 有作用域限制，有类型检查
4. inline 是函数？再编译器替换。有类型检查。

#### explicit 隐式类型转换

构造函数前加上 explicit 可以防止构造函数的参数在传递的时候进行隐式类型转换。

支队一个实参的构造函数有用，因为需要多个实参的构造函数不能用于隐式类型转换，也就不用指定为 explicit 了。



#### 堆和栈的区别

1. 大小、位置不同
   1. 栈空间比较小，向低地址增长。申请的地址是固定的。
   2. 堆空间比较大，向高地址增长。申请的位置可以变化。
2. 申请和管理方式不同
   1. 栈是系统自动分配的。自动回收。
   2. 堆要自己手动申请。由内存泄漏风险。
3. 申请效率不同
   1. 栈由系统分配，快且没有碎片。
   2. 堆由程序员分配，慢且会有碎片。
4. **取栈里的对象要快一些**，因为
   1. 寄存器里有栈地址
   2. 获取堆的内容要先读指针的内容，再读地址的内容。

#### new / delete 与 malloc / free 的异同

* 前者是 C++ 的关键字，调用 new 运算符，后者是 C/c++ 标准库函数。
* 前者自动算大小
* 前者会返回类型，是类型安全的。
* 前者会调用构造函数/析构函数
* 前者可以重载

new 会调用 operator new 申请空间，然后调用构造函数。

##### 重载`operator new`

```c++
class Foo {
public:
 void* operator new(std::size_t size, void* ptr)		// 只要保证第一个参数是 size_t
 {
     std::cout << "placement new" << std::endl;
  return ptr;
 }
}
int main()
{
 Foo* m = new Foo;
 Foo* m2 = new(m) Foo;	// 使用的时候传一个参数给 new
 std::cout << sizeof(m) << std::endl;
    // delete m2;
 delete m;
 return 0; 
}
```

可以用再内存池，不用重新申请空间，而是返回一个已经分配好空间的首地址。

##### 重载`operator delete`

一般不会重载 operator delete，原因是重载后的 operator delete **不能手动调用**。

这种重载的意义是**和重载`operator new`配套**。只有`operator new`报异常了，就会调用对应的`operator delete`。若没有对应的`operator delete`，则无法释放内存。

#### 不同类型的new

* plain new

  * ```c++
    void* operator new(std::size_t) throw(std::bad_alloc); // 会抛出 std::bad_alloc
    void operator delete(void *) throw();
    ```

* nothrow new

  * ```c++
    void * operator new(std::size_t,const std::nothrow_t&) throw(); // 失败时不抛出异常而是返回 Null
    void operator delete(void*) throw();
    ```

* placement new

  * ```c++
    void* operator new(size_t,void*);	// 不会分配内存，也就不会失败了
    void operator delete(void*,void*);
    ```

#### delete p、 delete [] p、 allocator 都有什么作用？

* delete [] 时，数组中的元素按照逆序进行销毁。
* delete p会调用一次析构函数，而delete[] p会**调用每个成员的析构函数**。
* delete[] 时候会**向前找4个字节获取长度**，这4个字节是未定义的，所以调用了**不固定次数**的析构函数
* allocator 将**内存分配和对象构造分开**，allocator 申请一部分内存，不进行初始化对象，只有需要的时候才会进行初始化操作。

#### malloc 和 free 是怎么实现的？

用系统调用 brk, mmap, munmap 这些系统调用实现。

* brk 是堆顶指针向高地址移动
* mmap 是在进程的虚拟空间中（文件映射区）找一快空闲的虚拟内存。
* 在第一次访问的时候，发生**缺页中断**，操作系统负责分配物理内存，然后简历虚拟内存和物理内存之间的映射关系。
* malloc**大于128k的内存**，使用mmap分配内存，在堆和栈之间找一块空闲内存分配(对应独立内存，而且初始化为0)，
* brk 分配的内存要等到高地址内存释放后才能释放，mmap可以单独释放。当高地址空间的空闲内存高于 128 k 执行内存紧缩。
* 操作系统有一个记录**空闲地址的链表**，当操作系统收到程序的申请就会遍历链表找到第一个大于申请空间的节点，然后删除这个节点。

brk 找K线链表的策略：

* 最优匹配：找到 >= M 的最小的节点
* 最差匹配：找到 >= M 的最大的节点
* 首次匹配
* 下次匹配

除了空闲链表的其他空闲内存方式：

* 分离分散链表：每一种大小的空间简历独立的链表

* **伙伴系统**：空闲空间递归一分为二直到满足。伙伴系统的伙伴只有1位不同，比较好找。



#### malloc realloc calloc

* realloc 用于扩容

```c++
void* malloc(unsigned int num_size);
int *p = malloc(20*sizeof(int)); // 申请20个int类型的空间；

void* calloc(size_t n,size_t size);
int *p = calloc(20, sizeof(int)); 	 // 省去计算，并且初始化为 0  

void realloc(void *p, size_t new_size); // 接收一个指针，在其后扩容。主要用于动态扩容。

```





#### 顶层const 底层const

顶层 const 修饰的**变量本身**是一个常量

底层 const 指的是 const 修饰的变量**指向的对象**是一个常量

#### final

禁止继承

禁止重写，C++中还允许将方法标记为fianal，这意味着无法再子类中重写该方法。这时final关键字至于方法参数列表后面，如下

#### 野指针和悬空指针

* 野指针：没有被初始化的指针 ==》 初始化
* 悬空指针：指针最初指向的内存被释放了  ==》 释放后立即置空

#### 重载重写和隐藏

* 重载 overload
  * 同名函数，参数不同
* 重写 override
  * 派生类覆盖基类的同名函数
  * 相同的参数个数、参数类型和返回值类型
* 隐藏
  * 派生类的函数屏蔽了基类的同名函数（可以用：：访问被隐藏的函数）
  * 参数相同，但是基类函数不是虚函数
  * **参数不同，无论基类函数是不是虚函数都会被隐藏**

#### 构造函数的类别

* 默认构造函数

* 初始化构造函数

* 拷贝构造函数

  * ```c++
    Student (const Student&);
    ```

* 移动构造函数

  * ```c++
    Student (Student&&);
    ```

* 委托构造函数

  * 被委托的构造函数在委托构造函数的初始化列表里被调用，而不是在委托构造函数的函数体里被调用。

* 转换构造函数

  * 只有一个其他类型的形参

#### 类成员初始化？构造函数顺序？初始化列表为什么快？

* 赋值初始化(在{}里初始化) 是先分配内存空间才初始化。

* 列表初始化时给数据成员分配空间的时候就初始化。初始化的时候函数体还没执行

派生类构造函数的执行顺序

1. 虚基类
2. 基类
3. 类类型成员的构造函数
4. 自己的构造函数

前者是构造函数里赋值，后者是纯粹的初始化操作。赋值操作有时候会产生临时对象。

#### 什么时候必须成员列表初始化？作用是什么？

其实就是什么时候不能用赋值初始化。

1. 引用成员
2. 常量成员
3. 基类带参数的构造函数
4. 类成员的带参数的构造函数

列表初始化实际上：

1. 编译器在构造函数内安插初始化操作。
2. 初始化顺序和声明顺序相关。







#### 浅拷贝和深拷贝

* 浅拷贝：只拷贝一个指针，不开辟新的地址
* 深拷贝：拷贝指针值，并且开辟出新的空间

#### 大端和小端

* 大端：高字节在低地址
* 小端：低字节在低地址



#### volatile mutable explicit

* volatile
  
  用 volatile 修饰的变量总是需要重新从地址读数据。
  
  * 表示变量**可以被编译器未知因素更改**（OS, Thread, hardware）
  * 编译器对访问该变量的代码不在进行优化
  * 总是重新从它所在的地址读取数据
  * **防止编译器把值放入寄存器**
  
* mutable
  * 意思是可变的，和 const 是反义词
  * 有些时候可能想在 const 函数里修改一些跟状态无关的数据成员
  
* explicit
  * 不能发生隐式类型转换
  * 只能加在构造函数声明上
  * 被 explicit 修饰的构造函数的类不能发生隐式类型转换

#### 异常处理

#### try throw catch

* catch(...) 可以捕获任何异常

* catch 的异常不想在本函数处理，可以在 catch 里抛出异常。

* 异常声明：

  * ```c++
    int fun() throw(int,double,A,B,C){...}; // throw 里声明能抛出的异常的列表
    ```

* 标准异常 exception

  * std::bad_typeid
  * std::bad_cast
  * std::bad_alloc
  * ...
  * ![C++ 异常的层次结构](https://www.runoob.com/wp-content/uploads/2015/05/exceptions_in_cpp.png)
  * 自定义异常
    * 方法：继承和重载 excepption 类

#### static

1. 隐藏在文件作用域
   1. 函数默认是 extern 声明的
   2. 定义静态函数可以在其他文件定义同名函数，并且不会被其他文件引用
2. 保持内容的持久，存储在静态存储区
3. **static 类对象必须在类外初始化**
   1. static 修饰的对象先于对象存在，因此要在类外初始化
4. static 对象不属于任何对象或者实例
   1. 因此不能被 virtual 修饰



#### main 函数之前做了什么事情？

* 设置栈指针
* 初始化 static 对象和 global 对象，也就是 .data 段的内容
* 将未初始化的全局变量赋予初值
* 全局对象初始化，也就是调用构造函数。（可以注入一些代码在 main 之前执行）
* 将 main 函数的参数 argc， argv 传递给 main 函数。

#### main 函数执行完之后呢？

* **全局对象的析构**

#### 野指针 悬空指针

野指针指向未知的区域

* 指针没有初始化

悬空指针

* 指针指向的内容已经被释放了。
* 或者声明周期已经结束了。

解决：

* 初始化
* 用指针的时候判断是不是空的
* 释放之后指针置为 nullptr
* 使用智能指针

#### 什么是内存泄漏

内存泄漏：分配的内存没有释放，导致这块内存不能被再次使用。

原因：

* new 了**没有 delete** 或者**没有 delete []**。
* 析构函数没有释放内存。
* 没有将**基类的析构函数没有声明为虚函数**
  * 否则 delete 派生类的基类指针的时候**派生类的析构函数被覆盖**不能正常析构。

> 《Effective C++》中的观点是，只要一个类有可能会被其它类所继承， 就应该声明虚析构函数。

* 有指针成员，但是**没有自己的拷贝构造函数 / 重载赋值运算符**。
* 返回值为野指针。
* 循环引用。

避免内存泄漏的方法：

* 引用计数法 类似于智能指针
* 在构造的时候 new，析构的时候 delete
* **将基类的虚函数声明为虚函数**
* 对象数组的释放用 **delete []** 也就是 new new[] delete delete[]配套
* 有 new 就别忘了 delete

检测工具

* Valgrind
* Asam

#### 面向对象三大特性

继承多态和封装

多态的方式：

* 覆盖：子类重写父类的虚函数。// 运行时多态
* 重载：允许同名函数，不同参数。// 编译时多态
* 模板，模板特化

#### 四种强制类型转换

上行转换：派生变基类：安全

下行转换：基类变派生：不安全

* reinterpret_cast<typeid> (exp)
  * 直接转
* const_cast<typeid> (exp)
  * 修改类型的 const 或者 volatile 属性
* static_cast<typeid> (exp)
  * **没有类型检查**，用于基类和派生类之间的转换
    * 上行 把派生类指针/引用换成基类的 ： 安全
    * 下行 把基类的指针/引用换成派生类 ： 不安全
  * 用于基本类型的转换
  * 空指针换成其他类型指针
* dynamic_cast<typeid> (exp)
  * **有类型检查**，基类向派生类转换比较安全
  * 在执行期的时候决定真正的类型。
  * 上行转换和 static_cast 一样
  * 下行转换时 dynamic_cast 有类型检查的功能
    * **dynamic_cast 会给出 nullptr**
    * **而 static_cast 会给出未定义！**

#### 不使用额外空间交换两数。

1. ```c++
   x = x + y;
   y = x - y;
   x = x - y;
   ```

2. ```c++
   x = x ^ y;
   y = x ^ y;
   x = x ^ y;
   ```

#### strcpy 和 memcpy 的区别

```c++
#include <cstring>
// 该函数返回一个指向最终的目标字符串 dest 的指针。
char *strcpy(char *dest, const char *src);

// 该函数返回一个指向目标存储区 str1 的指针。
void *memcpy(void *str1, const void *str2, size_t n);
```

1. strcpy 复制字符擦混
2. memcpy 复制任何内容
3. strcpy不用指定长度 ‘\0’
4. memcpy 要指定长度

#### 编译器的默认函数

* 默认缺省构造函数
* 默认拷贝构造函数
* 默认析构函数
* 默认赋值运算符
* .... 默认移动构造 默认移动赋值？

#### 迭代器

* 输入迭代器
* 输出迭代器
* 前向迭代器
* 双向迭代器
* 随机访问迭代器



## 高级特性

#### 虚继承

虚继承可以解决菱形继承的问题。不用复制多份基类。

* bptr 虚继承的子类指向父类的指针/偏移量，可能会和 vptr 合并。

链继承 C : B : A

```c++
                                                      C VTable（不完整)
struct C                                              +------------+
object                                                | RTTI for C |
    0 - struct B                            +-------> +------------+
    0 -   struct A                          |         |   C::f0()  |
    0 -     vptr_A -------------------------+         +------------+
    8 -     int ax                                    |   B::f1()  |
   12 -   int bx                                      +------------+
   16 - int cx                                        |   C::f2()  |
sizeof(C): 24    align: 8                             +------------+
```

多继承

C : A, B

* 一个物理虚函数表，两个虚函数表指针和两个逻辑虚函数表。

* 需要保存一个到虚函数顶部的 offset_to_top
  * 在多继承中，由于**不同的基类起点可能处于不同的位置**，因此当需要将它们转化为实际类型时，**`this`指针的偏移量也不相同**。由于实际类型在编译时是未知的，这要求**偏移量必须能够在运行时获取**。
  * 实体`offset_to_top`表示的就是实际类型起始地址到当前这个形式类型起始地址的偏移量。在向上动态转换到实际类型时，让**`this`指针加上这个偏移量**即可得到实际类型的地址。
* thunk: 解决子类 this 指针偏移问题
  * 为了弄清楚`Thunk`是什么，我们首先要注意到，如果一个类型`B` 的引用持有了实际类型为`C`的变量，这个引用的起始地址在`C+16`处。当它调用由类型`C`重写的函数`f1()`时，如果直接使用`this`指针调用`C::f1()`会由于`this`指针的地址多出`16`字节的偏移量导致错误。 因此在调用之前，`this`指针必须要被调整至正确的位置 。这里的`Thunk`起到的就是这个作用：**首先将`this` 指针调整到正确的位置，即减少`16`字节偏移量，然后再去调用函数`C::f1()`**。

```c++
                                                C Vtable (7 entities)
                                                +--------------------+
struct C                                        | offset_to_top (0)  |
object                                          +--------------------+
    0 - struct A (primary base)                 |     RTTI for C     |
    0 -   vptr_A -----------------------------> +--------------------+       
    8 -   int ax                                |       C::f0()      |
   16 - struct B                                +--------------------+
   16 -   vptr_B ----------------------+        |       C::f1()      |
   24 -   int bx                       |        +--------------------+
   28 - int cx                         |        | offset_to_top (-16)|
sizeof(C): 32    align: 8              |        +--------------------+
                                       |        |     RTTI for C     |
                                       +------> +--------------------+
                                                |    Thunk C::f1()   |
                                                +--------------------+
```



虚继承

**虚基类只存一次！子类存到虚基类的虚函数表的指针**

不使用虚继承，基类存多份

<img src="C:\Users\19183\AppData\Roaming\Typora\typora-user-images\image-20241008234528644.png" alt="image-20241008234528644" style="zoom:50%;" />

使用菱形继承，基类只存一份

<img src="C:\Users\19183\AppData\Roaming\Typora\typora-user-images\image-20241008235152183.png" alt="image-20241008235152183" style="zoom:50%;" />

B:A; C:A, D: B, C

* **虚基类偏移量** / **虚基类指针**？ （**和编译器有关！**可以是存在线性地址里，通过偏移量确定（g++），也可以开辟新的**虚基表**指针，指向虚基类的地址（vs））
* **虚基类由最后的子类实现**
  * 所以在最后的位置
  * 虚基类中被子类重写的函数需要指向 vcall_offset
    * 因为运行时才知道虚基类的 this 指针的位置。

```text
                                          D VTable
                                          +---------------------+
                                          |   vbase_offset(32)  |
                                          +---------------------+
struct D                                  |   offset_to_top(0)  |
object                                    +---------------------+
    0 - struct B (primary base)           |      RTTI for D     |
    0 -   vptr_B  ----------------------> +---------------------+
    8 -   int bx                          |       D::f0()       |
   16 - struct C                          +---------------------+
   16 -   vptr_C  ------------------+     |   vbase_offset(16)  |
   24 -   int cx                    |     +---------------------+
   28 - int dx                      |     |  offset_to_top(-16) |
   32 - struct A (virtual base)     |     +---------------------+
   32 -   vptr_A --------------+    |     |      RTTI for D     |
   40 -   int ax               |    +---> +---------------------+
sizeof(D): 48    align: 8      |          |       D::f0()       |
                               |          +---------------------+
                               |          |   vcall_offset(0)   |x--------+
                               |          +---------------------+         |
                               |          |   vcall_offset(-32) |o----+   |
                               |          +---------------------+     |   |
                               |          |  offset_to_top(-32) |     |   |
                               |          +---------------------+     |   |
                               |          |      RTTI for D     |     |   |
                               +--------> +---------------------+     |   |
                                          |     Thunk D::f0()   |o----+   |
                                          +---------------------+         |
                                          |       A::bar()      |x--------+
                                          +---------------------+     
```

**虚基类位于派生类存储空间的末尾。**

#### 虚函数指针和虚函数表的创建时机：

虚函数表是在编译的过程创建

虚函数指针在运行时创建



#### 构造函数、析构函数、虚函数能不能是内联函数？

* inline 只是个建议，所以语法上没有错误。

* effective C++ 里阐述：编译器不会真正的对 inline 的构造和析构函数进行内联操作，因为编译器要在构造和析构函数中添加额外的操作。（申请/释放内存，构造/析构对象）。实际上构造函数/析构函数要比看起来复杂。
* **对于虚函数，要分情况。**
  * 如果虚函数能在编译期就决定调用哪个函数，就可以进行内联。
  * **在对象里调用虚虚函数。**

#### 构造函数为什么不能是虚函数？析构函数为什么是虚函数？

* 构造函数
  * 存储上，没有实例化就没有vtable。调用构造函数的时候不能确定真实的类型。所以 ctor 不能是虚函数。
  * 构造函数只在初始化时运行一次，不是动态行为，没必要多态。
  * 构造函数第一件事就是初始化 vptr。
* 析构函数
  * 是为了防止内存泄漏。
  * 如果析构函数不是虚函数，就不能正确识别对象类型从而正确调用析构函数。如果不把析构函数弄成虚函数，基类指针指向派生类的时候就不会发生动态绑定。

#### 多个构造函数、析构函数顺序

* 构造函数
  * 基类构造函数，多个基类按照派生表中的顺序
  * 成员类构造函数，按照声明顺序
  * 派生类构造函数
* 析构函数
  * 派生类的虚构函数
  * 成员类的析构函数
  * 基类的析构函数

#### 构造函数内部执行顺序

1. 基类/虚基类构造
2. vptr 初始化
3. 扩展成员初始化列表
4. 执行程序员代码

#### 哪些函数不能是虚函数？

1. **构造**函数
2. **静态**函数
3. 友元函数
4. **普通**函数
5. **内联**函数

#### 模板类要写在一个文件里面

因为编译的时候模板不会生成真正的代码。实例化模板只能找到声明，链接器找不到链接程序会报错。

## c++ 内存管理

#### 类空间有什么

1. 非静态成员
2. 虚函数表指针
3. padding
4. 空类 size 为1

#### C++内存分区

栈

堆

全局数据

常量

代码段

## 异常处理

1. try throw catch





#### COREDUMP  

http://sunyongfeng.com/201609/programmer/tools/coredump

```bash
ulimit -c // 查看当前core 大小限制
ulimit -c unlimited // 解除限制
cat /etc/security/limits.conf // 查看限制
cat /proc/sys/kernel/core_pattern // 查看 core pattern 
// %t 时间戳
// %e 程序名
// %s 信号
// %p 进程号

// GDB 调试 coredump 
gdb a.out core-a.out

```

* bt 查看调用栈

* f n 查看某个栈帧

* info

  * info frame
  * info registers
  * info args
  * info locals
  * info threads 查看线程

  

  

  

  

## 编译连接

* 预处理 g++ **-E** main.cpp -o **main.i**
  * 删除注释
  * 引入头文件 #pragma once once
  * 宏展开

* 编译 g++ **-S** main.i -o **main.s**
  * 代码优化 指令重排？
  * 汇总所有的符号
    * 函数名修饰 (重载)

* 汇编 二进制可重定位文件 **main.o** 每个都有 text data bss heap 内核段，需要合并（链接）
  * 为什么合并？1. 浪费空间 2. 空间局部性不好
  * 汇编编程机器码

* 链接 可执行文件
  * **合并所有的 obj 文件的段**，**调整段的偏移和段长度**，**合并符号表**
  * 地址与空间分配
  * 符号解析与重定位

`.bss`节在目标文件和可执行文件中不占用文件的空间，但是它在装载时占用地址空间





TODO

#### 静态链接和动态链接

* 静态链接
  * 符号解析
  * 重定位
    * 作用：为了生成位置无关代码。这样共享库就可以放在任意的位置了。
    * 相对重定位条目
      * PC + 偏移量
    * 绝对重定位条目
      * 绝对地址
* 动态链接
  * 为了解决静态库的问题
    * 静态库更新程序需要重新链接
    * 共享代码节约资源
  * 一个库只有一个文件
  * 在内存中共享库的 .text 节可以被共享
  * 需要一个动态链接器
  * ![img](http://oss.interviewguide.cn/img/202205212343182.png)

#### 动态编译和静态编译

* 静态编译和动态编译是两种不同的编译方式，用于生成可执行文件。让我为您详细解释一下：
  1. **静态编译**：
     - 在静态编译时，编译器将程序**与其所有依赖项（包括库）链接在一起**，形成一个单独的可执行文件。
     - 这个可执行文件包含了所有代码和数据，因此它是一个完全独立的二进制文件。
     - 静态编译的优点是可执行文件**不依赖于外部动态链接库**，因此在运行时不需要加载其他库文件。
     - 缺点是可执行文件体积较大，且编译速度较慢。
  2. **动态编译**：
     - 在动态编译时，只创建程序的框架，而不将所有依赖项包含在可执行文件中。
     - 动态编译的**可执行文件需要附带一个动态链接库**，在执行时，需要调用其对应动态链接库中的命令。
     - 优点是**缩小了可执行文件本身的体积，加快了编译速度**，节省了系统资源。
     - 缺点是需要安装对应的运行库，否则无法运行动态编译的可执行文件。

#### 并发编程相关

### C++ 的锁

* 读写锁
* 互斥锁
  * 互斥机制
* 条件变量
  * 一种同步机制
* 自旋锁



## 智能指针相关

#### 1. enable_shared_from_this

允许一个类继承自它，以便获得指向 `this` 的 `shared_ptr` 

用处：异步回调，事件处理，观察者模式

**实现方法**



#### weak_ptr

* weak_ptr是为了配合shared_ptr而引入的一种智能指针，因为它不具有普通指针的行为，**没有重载`operator*`和`->`**,它的最大作用在于协助shared_ptr工作，像旁观者那样观测资源的使用情况。
* weak_ptr可以从一个shared_ptr或者另一个weak_ptr对象构造，获得资源的观测权。但weak_ptr没有共享资源，它的构造不会引起指针引用计数的增加。
* 使用weak_ptr的成员函数`use_count()`可以观测资源的引用计数，另一个成员函数`expired()`的功能等价于`use_count()==0`,但更快，表示被观测的资源(也就是shared_ptr的管理的资源)已经不复存在。
* weak_ptr可以使用一个非常重要的成员函数`lock()`从被观测的shared_ptr获得一个可用的shared_ptr对象， 从而操作资源。但当`expired()==true`的时候，`lock()`函数将返回一个存储空指针的shared_ptr。





## 调试相关

GDB 使用

内存泄漏

#### COREDUMP 调试

终止时产生 Coredump 文件，默认为 core 可以 echo “pattern” core_pattern 更改命名规则。



死锁？发个 kill -3 pid 或者 kill -s SIGQUIT pid 产生 core

然后 

```
gdb -c ./a.out ./core
gdb bt	// backtrace 查看调用栈
或者
gdb info stack // 显示变量信息

或者
pstack pid 看进程信息
```



#### 多线程调试







## C++ 并发编程

#### unique_lock vs lock_guard vs scope_lock

```c++
// 只能传入 std::adopt_lock
// 没有 lock，unlock 方法
lock_guard (mutex_type& m, adopt_lock_t tag);

// 
unique_lock(mutex_type& m, defer_lock_t t); // 延迟上锁
unique_lock(mutex_type& m, adopt_lock t);	
unique_lock(mutex_type& m, try_to_lock t); // 非阻塞尝试上锁


// 原子性地上多个锁，可以避免死锁
std::lock(...)
    
// std::lock 的 c++ 17 版本
std::scope_lock(mutex...)
```





### 异步 Promise future packaged_task async 

![std::future、std::promise、std::packaged_task 與 std::async 的關聯圖](https://zh-blog.logan.tw/static/images/2021/09/26/future-class-diagram.png)



### C++协程

#### 关键字

co_await 调用一个 awaiter 对象

co_yield 挂起一个协程

co_return 协程返回







写一个脚本，自动执行以下步骤：

1. 运行以上脚本
2. 执行 git pull
3. 执行 git commit -a -m {message}
4. 执行 git push

