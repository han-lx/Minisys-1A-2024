#pragma once
#define _CRT_SECURE_NO_WARNINGS
#include <string>
#include <iostream>

#define MAX_INSTRUCTION_COUNT 100 //最多命令数
#define ERROR_CODE 0xffffffff 
#define MIN_STACK_SIZE 30 //存储解析标签数量
#define MAX_LINES 4096 //最多可以支持的源代码行数


using namespace std;

typedef unsigned int code; //无符号数定义一条mips指令

//指令详细信息
typedef struct {
	char name[8];//指令名
	char type;//RIJ
	code op;
	code func;
} instruction;
//.text 段（代码段）或 .data 段（数据段）
struct segment 
{
	int length;
	int origin_pos;
	code* codes;
};
// mips代码整体结构
struct Mips {
	segment data;
	segment text;
};
//标签
typedef struct {
	char name[20];   // 标签名，如loop_start
	int address;//标签地址
	int type;//2：text 1：data
} label;
//标签堆栈
typedef struct {
	int maxlength;
	int pointer;
	label* content;
} labelStack;


//重定位表结构
typedef struct {
	unsigned int r_offset;  // 重定位位置（在节内的偏移量）
	string r_info;          // 符号信息（字符串表中的索引值）
	int r_type;             // 重定位类型：1 为绝对地址，2 为相对地址
	//相对地址计算方法为转移目标地址-pc地址，pc地址计算方法为所在节虚拟地址+重定位位置偏移+4
	int size;               // 重定位的操作数大小
} Elf32_Rel;

typedef struct {
	int address;//段的基地址
	int lineno;//段声明所在的行号
} segmentOri;


//文件读取输出
bool readFileToString(string file_name, string& fileData);
//输出文件
bool outputCode(string codeFile);

//汇编主逻辑
int compile(char* text);

//工具函数
//getErrorMessage：错误信息ErrorMessage
char* getErrorMessage();
//getAsmErrorMessage：错误信息AsmErrorMessage
bool getAsmErrorMessage(string codeFile);

//label处理
//searchLable：在符号表中查找标签名 name 并返回其信息。
label* searchLable(char* name);

//test 函数
 //寄存器名->寄存器号
int test_regsName2regsNum(char* instruction);
//主要汇编函数 二进制转换
code test_RtypeTransfer(int rd, int rs, int rt);
//十进制或十六进制字符串->无符号整数 0x021->33
int test_DecHex2Int(char* str);
//测试检查标签名合法性
void test_checkLabelName(char* name);
//测试移除空格
void test_removeSpace(char* s);
void test_data2code(char cbuffer[], code c, int count);
class myAssembler
{
};

