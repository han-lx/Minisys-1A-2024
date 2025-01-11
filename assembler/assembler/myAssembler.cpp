#include "myAssembler.h"
#include <string.h>
#include <iostream>
#include <fstream>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <regex>
#include <cstdlib>  


using namespace std;

char errorMessage[80];//错误信息
char AsmErrorMessage[2048] = { 0 };//asm错误信息
int Asmflag = 0;//是否编译成功的全局标志

//编译基本设置
static instruction instructions[MAX_INSTRUCTION_COUNT];//所有命令 instructions.txt
static int instCount;//命令行数 instructions.txt行数
Mips bin;// 编译生成的二进制文件结构
static labelStack labels;//输入的mips文件的标签

//重定位信息表
vector<Elf32_Rel> relTextTab;//.text 段的重定位信息
vector<Elf32_Rel> relDataTab;//.data 段的重定位信息
//寄存器名
const char* regsName[32] = {
	"$zero","$at", "$v0", "$v1", "$a0", "$a1", "$a2",
	"$a3", "$t0", "$t1", "$t2", "$t3", "$t4", "$t5",
	"$t6", "$t7", "$s0", "$s1", "$s2", "$s3", "$s4",
	"$s5", "$s6", "$s7", "$t8", "$t9", "$k0", "$k1",
	"$gp", "$sp", "$s8", "$ra"
};
//保留字
const char* reservedWord[9] = {
		".text", ".data", ".word",".half",".byte",".float",".double",".ascii",".asciiz"
};
//行信息及地址跟踪
static int textStartlineno = -1;//.text 段的起始行号
static int dataStartlineno = -1;//.data 段的起始行号
static int validTextCount = 0;//.text 段中的有效指令数
static int validDataCount = 0;//.data 段中的有效数据行数

//汇编文件行记录
static int lineCount = 0;//当前正在处理asmCode的行号，也是处理过的行数
static int inputLineCount = 0;//记录输入文件的总行数
static char* lines[MAX_LINES];//源文件中每一行代码的指针
static int dataFlag[MAX_LINES] = { 0 };//标记保留字类别 word：0 half：1 byte：2
static int lineMap[MAX_LINES];// 每一行对应的源文件中的原始行号

segmentOri oriVertex[100];//记录程序在汇编过程中遇到的各个段的基地址和所在行号
static int oriCount = 0;//汇编段信息记录数

// 0:text, 1:data
int currentState = 0;
int currentbaseAddress = 0;//段基地址



//instructions.txt文档
//loadInstructions：加载instructions.txt文档
int loadInstructions() {
    char fileName[] = "instructions.txt";
    FILE* codeRecord = fopen(fileName, "r");
    if (codeRecord == NULL) {
        //cout << "loadInstructions:open instruction.txt failed" << endl;
        strcpy_s(errorMessage, "loadInstructions:open instruction.txt failed");
        return -1;
    }
    instruction temp;
    int i = 0;
    while (fscanf(codeRecord, "%s %s %u %u",
        &(temp.name), &(temp.type), &(temp.op), &(temp.func)) == 4) {
        instructions[i++] = temp;
    }
    fclose(codeRecord);
    instCount = i;
    return i;
}
//findInstructionIndex：查找指令在instructions中的索引
static int findInstructionIndex(char* name) {
    for (int i = 0; i < instCount; ++i) {
        if (strcmp(instructions[i].name, name) == 0) {
            return i;
        }
    }
    //cout << "findInstruction:instruction not support" << endl;
    strcpy_s(errorMessage, "findInstruction:instruction not support");
    return -1;
}
//findInstName：查找指令名
char findInstName(code op, code func, char* name) {
    for (int i = 0; i < instCount; ++i) {
        if (instructions[i].op == op && instructions[i].func == func) {
            strcpy(name, instructions[i].name);
            return instructions[i].type;
        }
    }
    return 0;
}

//label处理
//initlablesStack：初始化标签栈 labels，为其分配内存
static int initlablesStack() {
	labels.content = (label*)malloc(sizeof(label) * MIN_STACK_SIZE);
	if (labels.content == NULL) {
		strcat(AsmErrorMessage, "initlablesStack：malloc fail!\n");
		//exit(1);
		return 1;
	}
	labels.pointer = 0;
	labels.maxlength = MIN_STACK_SIZE;
	return 0;
}
//destrylabelStack：释放内存
static void destrylabelStack() {
	free(labels.content);
}
//checkLabelName：检查标签名是否有效 1:有效 0:无效
static int checkLabelName(char* name) {
	int result = 0;
	char* temp = name;
	if (strlen(temp) > 19) {
		strcpy(errorMessage, "checkLabelName：labelname is too long");
		return result;
	}
	for (int i = 0; i < 32; i++) {//避免和寄存器名字冲突
		if (strcmp(temp, regsName[i]) == 0) {
			strcpy(errorMessage, "checkLabelName：labelname conflicts with register name ");
			return result;
		}
	}
	for (int i = 0; i < 9; i++) {//避免保留字冲突
		if (strcmp(temp, reservedWord[i]) == 0) {
			strcpy(errorMessage, "checkLabelName：labelname conflicts with reserved words");
			return result;
		}
	}
	// 标签开头合法，继续检查后续字符
	if (*temp == '_' || (*temp >= 'a' && *temp <= 'z') || (*temp >= 'A' && *temp <= 'Z')) {
		temp++;
	}
	else {
		strcpy(errorMessage, "checkLabelName：Invalid first character");
		return result;
	}
	while (*temp)
	{
		if ((*temp >= 'a' && *temp <= 'z' || *temp >= 'A' && *temp <= 'Z')
			|| ((*temp) >= '0' && (*temp) <= '9')
			|| (*temp == '.' || *temp == '$'|| *temp == '_')) {
			result = 1;
		}
		else {
			result = 0;
			strcpy(errorMessage, "labelname is invalid");
			break;
		}
		temp++;
	}
	return result;
}
//addLabel：将标签 a 添加到标签栈
static void addLabel(label a) {
	if (labels.pointer < labels.maxlength) {
		labels.content[labels.pointer].address = a.address;
		labels.content[labels.pointer].type = a.type;
		if (checkLabelName(a.name) == 1)
		strcpy(labels.content[labels.pointer++].name, a.name);
	}
	else {//栈已满，动态扩展内存
		label* previous = labels.content;
		label* newc = (label*)malloc(sizeof(label) * labels.maxlength * 2);
		if (newc == NULL) {
			strcat(AsmErrorMessage, "addLabel：malloc fail!\n");
			exit(1);
		}
		for (int i = 0; i < labels.maxlength; ++i) {
			newc[i].address = previous[i].address;
			strcpy(newc[i].name, previous[i].name);
		}
		free(previous);
		labels.content = newc;
		labels.maxlength = labels.maxlength * 2;
		addLabel(a);
	}
}
//searchLable：标签栈中按名字搜索标签
label* searchLable(char* name) {
	for (int i = 0; i < labels.pointer; ++i) {
		if (strcmp(labels.content[i].name, name) == 0) {
			return &(labels.content[i]);
		}
	}
	return NULL;
}
//根据标签的名字和类型查找并处理标签地址
static  int solveLabelAddress(char* labelname, char type) {
	label* lp = searchLable(labelname);
	if (lp == NULL) {
		strcpy_s(errorMessage, "getLabelAddress:label not found");
		return 1;
	}
	if (type == 'I') {
		if (currentState == 0) {
			sprintf(labelname, "%d", (lp->address - (bin.text.length + 1) * 4 - currentbaseAddress) / 4);
		}
		else {
			sprintf(labelname, "%d", (lp->address - (bin.data.length + 1) * 4 - currentbaseAddress) / 4);
		}
	}
	else if (type == 'J') {
		sprintf(labelname, "%d", (lp->address - currentbaseAddress));
	}
	return 0;
}

//工具函数
//检查寄存器合法性
static int checkReg(int num) {
	if (num < 0 || num > 31) {
		//cout << "checkReg:register out of range" << endl;
		strcpy(errorMessage, "checkReg:register out of range");
		return 1;
	}
	return 0;
}
//getErrorMessage：错误信息ErrorMessage
char* getErrorMessage() {
	return errorMessage;
}
//getAsmErrorMessage：错误信息AsmErrorMessage
bool getAsmErrorMessage(string codeFile) {
	cout << AsmErrorMessage;
	ofstream codefile(codeFile.c_str(), ios::binary | ios::out);
	if (!(codefile.is_open()))
	{
		cout << "打开文件失败" << endl;
		return 0;
	}
	if (codefile) {
		codefile << AsmErrorMessage;
	}
	return 1;
}
//removeSpace：移除空格
static void removeSpace(char* s) {
    char* p = s;
    while (*s) {
        if (isspace(*s)) s++;
        else *(p++) = *(s++);
    }
    *p = 0;
}
//DecHex2Int：十进制或十六进制字符串->无符号整数 0x021->33
static unsigned int DecHex2Int(char* str) {
    // 判断输入是否为16进制
    string pattern = "0[xX][0-9a-fA-F]+";
    regex re(pattern);
    if (regex_match(str, re))
    {
        int hex = 0;
        sscanf(str, "%x", &hex);
        return hex;
    }
    // 判断输入是否为10进制
    string pattern2 = "^[0-9]*$";
    regex reg(pattern2);
    if (regex_match(str, reg))
    {
        int oct = 0;
        sscanf(str, "%d", &oct);
        return oct;
    }
    else {// 123a->123
        unsigned int offset = 0;
        sscanf(str, "%d", &offset);
        return offset;
    }
}
//寄存器名->寄存器号
static int regsName2regsNum(char* instruction) {
    char* _peek;
    char name[10];
    char instbuffer[50];
    int nameIndex = 0;
    char* temp = instruction;
    while (*temp) {
        nameIndex = 0;
        while (*temp && *temp != '$') temp++;
        if (*temp == '$') {
            _peek = temp;
            while (*_peek && *_peek != ',' && *_peek != ')') name[nameIndex++] = *_peek++;
            name[nameIndex] = 0;
            if (isalpha(name[1])) //isalpha()判断是否为字母
            {
                int i;
                //找到regsName的索引
                for (i = 0; i < 32; ++i) {
                    if (strcmp(name, regsName[i]) == 0) {
                        break;
                    }
                }
                if (i >= 32) {
                    //cout << "regsName2regsNum:invalid register name" << endl;
                    strcpy_s(errorMessage, "regsName2regsNum:invalid register name");
                    return 1;
                }
                *temp = 0;
                //cout << temp << endl;
                strcpy(instbuffer, instruction);
                //cout << temp << endl;
                temp = instbuffer + strlen(instbuffer);
                //cout << temp << endl;
                sprintf(temp, "$%d", i);
                //cout << temp << endl;
                temp = temp + strlen(temp);
                //cout << temp << endl;
                strcpy(temp, _peek);
                //cout << temp << endl;
                strcpy(instruction, instbuffer);
                temp = instruction;
                //cout << temp << endl;
            }
            else {
                temp = _peek;
            }
        }
    }
    return 0;
}
//data2code：把数据转换成0x格式的十六进制数
static void data2code(char cbuffer[], code c, int count) {
	char* wordbuffer = (char*)malloc(sizeof(char) * 24);
	if (wordbuffer == NULL) {
		strcat(AsmErrorMessage, "data2code：malloc fail!\n");
		exit(1);
	}
	memcpy(&c, cbuffer, sizeof(char) * count);
	sprintf(wordbuffer, "%x", c);
	char* temp = new char[11];
	char tmp[11] = "0x";
	strcat(tmp, wordbuffer);
	strcpy(temp, tmp);
	lineMap[lineCount] = inputLineCount;
	int i = lineCount;
	lines[lineCount++] = temp;
	validDataCount++;
	return;
}
//outputCodeProcess:处理输出文件为coe格式
static string outputCodeProcess(string outbody, size_t groupSize) {
	string formattedOutput=""; // 存储格式化后的结果
	size_t totalLength = outbody.length();
	// 将十六进制字符串按字节切割，并转换为整数
	// 循环遍历输入字符串，按 groupSize 切割
	for (size_t i = 0; i < totalLength; i += groupSize) {
		formattedOutput += outbody.substr(i, groupSize) + ","; 
		// 每行结束后添加换行符
		formattedOutput += "\n";
	}
	formattedOutput[formattedOutput.size() - 2] = ';';
	return formattedOutput;
}

//主要汇编函数 二进制转换
static code RtypeTransfer(char* name, int rd, int rs, int rt) {
    int index = findInstructionIndex(name);
    if (index == -1) {
        return ERROR_CODE;
    }
    if (checkReg(rs) | checkReg(rt) | checkReg(rd)) {
        return ERROR_CODE;
    }
    code r = 0;
    r |= instructions[index].func;
    r |= rd << 11;
    r |= rt << 16;
    r |= rs << 21;
    r |= instructions[index].op << 26;
    return r;
}
static code ItypeTransfer(char* name, int rt, int rs, int imm) {
	//cout << imm<<endl;
    int index = findInstructionIndex(name);
    if (index == -1) {
        return ERROR_CODE;
    }
    if (checkReg(rs) | checkReg(rt)) {
        return ERROR_CODE;
    }
    if (imm > 65536 || imm < -32768) {
        //cout << "ItypeTransfer:immediate value out of range" << endl;
        strcpy_s(errorMessage, "ItypeTransfer:immediate value out of range");
        return ERROR_CODE;
    }
    code i = 0;
    code immc = imm & 0x0000ffff;//只要16位
    i |= instructions[index].op << 26;
    i |= rt << 16;
    i |= rs << 21;
    i |= immc;
    return i;
}
static code JtypeTransfer(char* name, int addr) {
    int index = findInstructionIndex(name);
    if (index == -1) {
        return ERROR_CODE;
    }
    if (addr > 67108863 || addr < 0) {
        //cout << "JtypeToBinary:jump address value out of range" << endl;
        strcpy_s(errorMessage, "JtypeToBinary:jump address value out of range");
        return ERROR_CODE;
    }
    code j = 0;
    j |= instructions[index].op << 26;
    j |= addr;
    return j;
}
static code transToBinary(char* instruction) {
	//去除开头的空格
	while (isspace(*instruction)) instruction++;

	char inst[50];
	if (sscanf(instruction, "%s", inst) != 1) {
		strcpy_s(errorMessage, "transToBinary:instruction extraction error");
		return ERROR_CODE;
	}
	if (strlen(inst) > 50) {
		printf("transToBinary:instruction too long. terminated.\n");
		exit(0);
	}
	instruction += strlen(inst);
	int index = findInstructionIndex(inst);
	if (index == -1) {
		return ERROR_CODE;
	}

	removeSpace(instruction);

	if (regsName2regsNum(instruction)) {
		return ERROR_CODE;
	}

	code c = ERROR_CODE;

	if (instructions[index].type == 'R') {
		int rd = 0, rs = 0, rt = 0;
		if (sscanf_s(instruction, "$%d,$%d,$%d", &rd, &rs, &rt) != 3) {
			strcpy_s(errorMessage, "transToBinary:type == 'R' syntax error");
			return ERROR_CODE;
		}
		c = RtypeTransfer(inst, rd, rs, rt);
	}
	else if (instructions[index].type == 's') {
		int rs = 0, rt = 0, rd = 0;
		if (sscanf_s(instruction, "$%d,$%d", &rs, &rt) != 2) {
			strcpy_s(errorMessage, "transToBinary:type == 's' syntax error");
			return ERROR_CODE;
		}
		c = RtypeTransfer(inst, rd, rs, rt);
	}
	else if (instructions[index].type == 't') {
		int rs = 0, rt = 0, rd = 0;
		if (sscanf_s(instruction, "$%d", &rd) != 1) {
			strcpy_s(errorMessage, "transToBinary:type == 't' syntax error");
			return ERROR_CODE;
		}
		c = RtypeTransfer(inst, rd, rs, rt);
	}
	else if (instructions[index].type == 'u') {
		int rs = 0, rt = 0, rd = 0;
		if (sscanf_s(instruction, "$%d", &rs) != 1) {
			strcpy_s(errorMessage, "transToBinary:type == 'u' syntax error");
			return ERROR_CODE;
		}
		c = RtypeTransfer(inst, rd, rs, rt);
	}
	else if (instructions[index].type == 'v') {
		int rd = 0, rs = 0, rt = 0, sel = 0;
		if (sscanf_s(instruction, "$%d,$%d,%d", &rt, &rd, &sel) != 3 || sel > 3) {
			strcpy_s(errorMessage, "transToBinary:type == 'v' syntax error");
			return ERROR_CODE;
		}
		c = RtypeTransfer(inst, rd, rs, rt);
		c |= sel;

	}
	else if (instructions[index].type == 'w') {
		int rd = 0, rs = 4, rt = 0, sel = 0;
		if (sscanf_s(instruction, "$%d,$%d,%d", &rt, &rd, &sel) != 3 || sel > 3) {
			strcpy_s(errorMessage, "transToBinary:type == 'w' syntax error");
			return ERROR_CODE;
		}
		c = RtypeTransfer(inst, rd, rs, rt);
		c |= sel;

	}
	else if (instructions[index].type == 'x') {
		int rd = 0, rs = 0, rt = 0, shamt = 0;
		if (sscanf_s(instruction, "$%d,$%d,%d", &rd, &rt, &shamt) != 3 || shamt > 32) {
			strcpy_s(errorMessage, "transToBinary:type == 'x' syntax error");
			return ERROR_CODE;
		}
		c = RtypeTransfer(inst, rd, rs, rt);
		c |= shamt << 6;
	}
	else if (instructions[index].type == 'y') {
		int rd = 0, rs = 0, rt = 0;
		if (sscanf_s(instruction, "$%d,$%d,$%d", &rd, &rt, &rs) != 3) {
			strcpy_s(errorMessage, "transToBinary:type == 'y' syntax error");
			return ERROR_CODE;
		}
		c = RtypeTransfer(inst, rd, rs, rt);
	}
	else if (instructions[index].type == 'z') {
		int rd = 0, rs = 0, rt = 0;
		if (sscanf_s(instruction, "$%d", &rs) != 1) {
			strcpy_s(errorMessage, "transToBinary:type == 'z' syntax error");
			return ERROR_CODE;
		}
		c = RtypeTransfer(inst, rd, rs, rt);
	}
	else if (instructions[index].type == 'a') {
		int rd = 0, rs = 0, rt = 0;
		if (sscanf_s(instruction, "$%d,$%d", &rd, &rs) != 2) {
			strcpy_s(errorMessage, "transToBinary:type == 'a' syntax error");
			return ERROR_CODE;
		}
		c = RtypeTransfer(inst, rd, rs, rt);
	}
	//软件参数
	else if (instructions[index].type == 'b') {
		c = RtypeTransfer(inst, 0, 0, 0);
	}
	else if (instructions[index].type == 'c') {
		c = RtypeTransfer(inst, 0, 16, 0);
	}
	else if (instructions[index].type == 'I') {
		int rs, rt, imm = 0;
		char temp[50] = { 0 };
		char* p = instruction + strlen(instruction) - 1;
		while (*p != ',' && p > instruction) p--;
		if (p == instruction) {//无逗号
			strcpy_s(errorMessage, "transToBinary:type == 'I' syntax error1");
			return ERROR_CODE;
		}
		p++;
		cout << instruction << endl;
		if (sscanf(instruction, "$%d,$%d,%s", &rt, &rs, temp) != 3) {
			strcpy_s(errorMessage, "transToBinary:type == 'I' syntax error2");
			return ERROR_CODE;
		}
		imm = DecHex2Int(temp);
		c = ItypeTransfer(inst, rt, rs, imm);
	}
	else if (instructions[index].type == 'l') {
		int rs, rt, imm = 0;
		char temp[50] = { 0 };
		char* p = instruction + strlen(instruction) - 1;
		while (*p != ',' && p > instruction) p--;
		if (p == instruction) {//无逗号
			strcpy_s(errorMessage, "transToBinary:type ==  'l' syntax error");
			return ERROR_CODE;
		}
		p++;
		//type == 'l'  如bne $t2,$zero,done
		if (isalpha(*p) || (*p == '_')) {
			Elf32_Rel rel;
			rel.r_offset = (bin.text.length) * 32 + 16;
			rel.r_info = searchLable(p)->name;
			rel.r_type = 2;
			rel.size = 16;
			relDataTab.push_back(rel);
			int r = solveLabelAddress(p, 'I');
			if (r) {
				return ERROR_CODE;
			}
		}
		if (sscanf(instruction, "$%d,$%d,%s", &rt, &rs, temp) != 3) {
			strcpy_s(errorMessage, "transToBinary:type ==  'l' syntax error");
			return ERROR_CODE;
		}
		imm = DecHex2Int(p);
		c = ItypeTransfer(inst, rs, rt, imm);
	
	}
	//todo:默认立即数为十进制数
	else if (instructions[index].type == 'j') {
		int rs = 0, rt,imm;
		cout << instruction<<endl;
		if (sscanf(instruction, "$%d,%d", &rt, &imm) != 2) {
			strcpy_s(errorMessage, "transToBinary:type == 'j' syntax error");
			return ERROR_CODE;
		}
		//cout << imm << endl;
		c = ItypeTransfer(inst, rt, rs, imm);
	}
	else if (instructions[index].type == 'k') {
		int rs, rt, offset = 0;
		char buffname[50];
		char chr[50] = { 0 };
		//接受字符 %[^(]从当前位置开始读取字符，直到遇到 (
		if (sscanf(instruction, "$%d,%[^(]($%d)", &rt, buffname, &rs) == 3) {
			label* lp = searchLable(buffname);
			if (lp != NULL) {
				offset = lp->address;
				c = ItypeTransfer(inst, rt, rs, offset);
				Elf32_Rel rel;
				rel.r_offset = (bin.text.length) * 32 + 16;
				rel.r_info = lp->name;
				rel.r_type = 1;
				rel.size = 16;
				relDataTab.push_back(rel);
			}
			else if (sscanf(instruction, "$%d,%[^(]($%d)", &rt, chr, &rs) == 3) {
				offset = DecHex2Int(chr);
				c = ItypeTransfer(inst, rt, rs, offset);
			}
			else {
				strcpy_s(errorMessage, "transToBinary:type == 'k' label not find");
			}
		}
		else {
			strcpy_s(errorMessage, "transToBinary:type == 'k' syntax error");
			return ERROR_CODE;
		}
	}
	else if (instructions[index].type == 'm' || instructions[index].type == 'n' || instructions[index].type == 'o' || instructions[index].type == 'p') {
		int rs, rt = 1, imm = 0;
		char chr[11] = { 0 };
		char* p = instruction + strlen(instruction) - 1;
		while (*p != ',' && p > instruction) p--;
		if (p == instruction) {
			strcpy_s(errorMessage, "transToBinary:type == 'mnop'syntax error");
			return ERROR_CODE;
		}
		p++;
		if (isalpha(*p)) {
			Elf32_Rel rel;
			rel.r_offset = (bin.text.length) * 32 + 16;
			rel.r_info = searchLable(p)->name;
			rel.r_type = 2;
			rel.size = 16;
			relDataTab.push_back(rel);
			int r = solveLabelAddress(p, 'I');
			if (r) {
				return ERROR_CODE;
			}
		}
		if (sscanf(instruction, "$%d,%s", &rs, chr) != 2) {
			strcpy_s(errorMessage, "transToBinary:type == 'mnop'syntax error");
			return ERROR_CODE;
		}
		imm = DecHex2Int(chr);
		if (instructions[index].type == 'm') {
			c = ItypeTransfer(inst, 1, rs, imm);
		}
		else if (instructions[index].type == 'n') {
			c = ItypeTransfer(inst, 0, rs, imm);
		}
		else if (instructions[index].type == 'o') {
			c = ItypeTransfer(inst, 17, rs, imm);
		}
		else if (instructions[index].type == 'p') {
			c = ItypeTransfer(inst, 16, rs, imm);
		}
	}
	else if (instructions[index].type == 'J') {
		int addr;
		//如果指令参数（instruction）的第一个字符是字母（isalpha 检查）或_，则它被视为 标签名 而不是直接地址。
		if (isalpha(instruction[0])|| (instruction[0]=='_')) {
			Elf32_Rel rel;
			rel.r_offset = (bin.text.length) * 32 + 6;
			label* lp = searchLable(instruction);
			if (lp == NULL) {
				strcpy_s(errorMessage, "transToBinary:type == 'J'label not found");
				return ERROR_CODE;
			}
			rel.r_info = lp->name;
			rel.r_type = 1;
			rel.size = 26;
			relTextTab.push_back(rel);
			int r = solveLabelAddress(instruction, 'J');
			if (r) {
				return ERROR_CODE;
			}
		}
		if (sscanf_s(instruction, "%d", &addr) != 1) {
			strcpy_s(errorMessage, "transToBinary:type == 'J'syntax error");
			return ERROR_CODE;
		}
		c = JtypeTransfer(inst, addr / 4);
	}
	else if (instructions[index].type == 'K') {
		c = RtypeTransfer(inst, 0, 0, 0);
	}
	return c;
}
//处理.word .half .byte类型数据行
static code convertDataline_word(char* line) {
	code c = 0;
	char str[100] = { 0 };
	sscanf(line, "%[^,]", str);
	c = DecHex2Int(str);
	return c;
}
static code convertDataline_half(char* line) {
	code c = 0;
	char strl[100] = { 0 };
	char strh[100] = { 0 };
	if (sscanf(line, "%[^,],%[^,]", strl, strh) == 2) {
		c = DecHex2Int(strl);
		c |= DecHex2Int(strh) << 16;
	}
	else {
		sscanf(line, "%[^,]", strl);
		c = DecHex2Int(strl);
	}
	return c;
}
static code convertDataline_byte(char* line) {
	code c = 0;
	char str1[100] = { 0 };
	char str2[100] = { 0 };
	char str3[100] = { 0 };
	char str4[100] = { 0 };
	if (sscanf(line, "%[^,],%[^,],%[^,],%[^,]", str1, str2, str3, str4) == 4) {
		c = DecHex2Int(str1);
		c |= DecHex2Int(str2) << 8;
		c |= DecHex2Int(str3) << 16;
		c |= DecHex2Int(str4) << 24;
	}
	else if (sscanf(line, "%[^,],%[^,],%[^,]", str1, str2, str3) == 3) {
		c = DecHex2Int(str1);
		c |= DecHex2Int(str2) << 8;
		c |= DecHex2Int(str3) << 16;
	}
	else if (sscanf(line, "%[^,],%[^,]", str1, str2) == 2) {
		c = DecHex2Int(str1);
		c |= DecHex2Int(str2) << 8;
	}
	else {
		c = DecHex2Int(str1);
	}
	return c;
}
//汇编
//firstProcessAsmCode：移除注释，解析label，处理保留字
static char* firstProcessAsmCode(char* line, int lineno) {
	char* t = line;
	char* p;
	p = line;
	//清除注释
	while ((*p) && ((*p) != '#')) p++;
	if (*p == '#') {
		*p = 0;//找到第一个 # 并将其替换为 \0，从而截断后续内容
	}
	p = line;
	if ((p = strstr(line, ".data"))) { //strstr()：在一个字符串中查找另一个子字符串首次出现的位置
		p += 5;
		if (dataStartlineno == -1) {
			dataStartlineno = lineno;
			validDataCount = 0;
			currentState = 1;
		}
		else {
			strcpy(errorMessage, "firstProcessAsmCode：.data label syntex error1");
			return NULL;
		}
		while (*p && !isspace(*p)) p++;
		if (*p != '\0') {
			segmentOri o;
			o.lineno = lineno;
			while (isspace(*p)) p++;
			int n = sscanf(p, "%x", &(o.address));
			currentbaseAddress = o.address;
			while (*p && !isspace(*p)) p++;
			if (n != 1) {
				strcpy(errorMessage, "firstProcessAsmCode：.data label syntex error2");
				return NULL;
			}
			else {
				oriVertex[oriCount++] = o;
			}
		}
	}
	else if ((p = strstr(line, ".text"))) {
		p += 5;
		if (textStartlineno == -1) {
			textStartlineno = lineno;
			validTextCount = 0;
			currentState = 0;
		}
		else {
			strcpy(errorMessage, "firstProcessAsmCode：.text label syntex error");
			return NULL;
		}
		while (*p && !isspace(*p)) p++;
		if (*p != '\0') {
			segmentOri o;
			o.lineno = lineno;
			while (isspace(*p)) p++;
			int n = sscanf(p, "%x", &(o.address));
			currentbaseAddress = o.address;
			while (*p && !isspace(*p)) p++;
			if (n != 1) {
				strcpy(errorMessage, "firstProcessAsmCode：.text label syntex error");
				return NULL;
			}
			else {
				oriVertex[oriCount++] = o;
			}
		}
	}

	if (p == NULL)
		p = line;
	while (isspace(*p)) p++;

	//移除标签
	char* p1;
	char labelName[20] = "";
	while ((p1 = strchr(p, ':'))) {
		//isalnum()检查字符是否是字母或数字
		while ((isalpha(*(p1 - 1)) || isalnum(*(p1 - 1))||(*(p1 - 1) == '_')) && (p1 - 1 >= p)) {
			p1--;
			if (p1 == p) break;
		}
		char* temp = strchr(p1, ':');
		*temp = 0;//冒号位置的字符替换为字符串结束符 '\0'，截出标签
		//cout << p1 << endl;
		//int n = sscanf_s(p1, "%s", labelName, _countof(labelName));
		int n = sscanf_s(p1, "%s", labelName, (unsigned int)_countof(labelName));
		/*cout << n << endl;
		cout << labelName << endl;
		cout << strlen(labelName) << endl;*/
		if (n == 0 || strlen(labelName) == 0) {
			strcpy(errorMessage, "firstProcessAsmCode：label syntex error");
			//cout << "error1" << endl;
			return NULL;
		}
		p1 = temp + 1;
		p = p1;
		//cout << p << endl;

		label a;
		if (currentState == 0) {
			a.address = validTextCount * 4 + currentbaseAddress;
			a.type = 2;
		}
		else {
			a.address = validDataCount * 4 + currentbaseAddress;
			a.type = 1;
		}
		strcpy(a.name, labelName);
		addLabel(a);
		line = t;
	}

	//处理保留字
	while (isspace(*p)) p++;
	if (*p != 0) {
		if (currentState == 0) {
			validTextCount++;
		}
		else {
			char stylebuffer[30];
			sscanf_s(p, "%s", stylebuffer, _countof(stylebuffer));

			//.word
			if (strcmp(stylebuffer, ".word") == 0) {
				p += strlen(stylebuffer);
				while (isspace(*p)) p++;
				removeSpace(p); // remove space
				while (*p != 0) {
					dataFlag[lineCount] = 0;//.word
					lineMap[lineCount] = inputLineCount;
					char* instbuffer = (char*)malloc(sizeof(char) * strlen(p) + 32);
					if (instbuffer == NULL) {
						strcat(AsmErrorMessage, "firstProcessAsmCode：.word malloc fail!\n");
						exit(1);
					}
					strcpy(instbuffer, p);
					lines[lineCount++] = instbuffer;
					validDataCount++;
					while (*p && *p != ',') p++; //
					if (*p == ',') {
						*p = 0;
						p++;
					}
				}
			}
			//.half
			else if (strcmp(stylebuffer, ".half") == 0) {
				p += strlen(stylebuffer);
				while (isspace(*p)) p++;
				removeSpace(p);
				while (*p != 0) {
					dataFlag[lineCount] = 1;//.half
					lineMap[lineCount] = inputLineCount;
					char* instbuffer = (char*)malloc(sizeof(char) * strlen(p) + 32);
					if (instbuffer == NULL) {
						strcat(AsmErrorMessage, "malloc fail!\n");
						exit(1);
					}
					strcpy(instbuffer, p);
					char str1[16] = { 0 }, str2[16] = { 0 }, str3[16] = { 0 }, str4[16] = { 0 };
					if (sscanf(instbuffer, "%[^,],%[^,]", str1, str2) <= 2) {
						lines[lineCount++] = instbuffer;
						for (int i = 0; i < 2; i++) {
							while (*p && *p != ',') p++;
							if (*p == ',') {
								*p = 0;
								p++;
							}
						}
						validDataCount++;
					}
				}
			}
			//.byte
			else if (strcmp(stylebuffer, ".byte") == 0) {
				p += strlen(stylebuffer);
				while (isspace(*p)) p++;
				removeSpace(p); // remove space
				while (*p != 0) {
					dataFlag[lineCount] = 2;
					lineMap[lineCount] = inputLineCount;
					char* instbuffer = (char*)malloc(sizeof(char) * strlen(p) + 32);
					if (instbuffer == NULL) {
						strcat(AsmErrorMessage, "malloc fail!\n");
						exit(1);
					}
					strcpy(instbuffer, p);
					char str1[16] = { 0 }, str2[16] = { 0 }, str3[16] = { 0 }, str4[16] = { 0 };
					if (sscanf(instbuffer, "%[^,],%[^,],%[^,],%[^,]", str1, str2, str3, str4) <= 4) {
						lines[lineCount++] = instbuffer;
						for (int i = 0; i < 4; i++) {
							while (*p && *p != ',') p++; // move the digits in the line
							if (*p == ',') {
								*p = 0;
								p++;
							}
						}
						validDataCount++;
					}
				}
			}
			//.ascii
			else if (strcmp(stylebuffer, ".asciiz") == 0) {
				p += strlen(stylebuffer);
				while (isspace(*p)) p++;
				if (*p != '"') {
					strcpy(errorMessage, "asciiz syntex error");
					return NULL;
				}
				p++;
				char cbuffer[4];
				code c = 0;
				int ccount = 0;
				while (*p && *p != '"') {
					if (ccount == 4) {
						data2code(cbuffer, c, 4);
						ccount = 0;
					}
					else {
						cbuffer[ccount++] = *p++;
					}
				}
				if (*p == '"') {
					p++;
				}
				else {
					strcpy(errorMessage, "asciiz syntex error");
					return NULL;
				}
				if (ccount != 0) {
					c = 0;
					if (ccount == 4) {
						data2code(cbuffer, c, ccount);
						cbuffer[0] = '\0';
						data2code(cbuffer, c, 1);
					}
					else {
						cbuffer[ccount] = '\0';
						data2code(cbuffer, c, ccount);
					}
				}
			}
		}
	}
	return p;
}
//ProcessAsmCode：逐行解析汇编代码
static int ProcessAsmCode(char* text) {
	char* line;
	char* buf;
	line = strtok_s(text, "\n", &buf);
	int errorState = 0;
	currentbaseAddress = 0;
	//预处理每一行
	while (line) {
		inputLineCount++;
		while (isspace(*line)) line++;
		if (*line != 0) {
			line = firstProcessAsmCode(line, lineCount);
			if (line == NULL) {
				char errorbuffer[256];
				printf(AsmErrorMessage, "ProcessAsmCode:ERROR: line number %d\n message %s\n", inputLineCount, errorMessage);
				strcat(AsmErrorMessage, errorbuffer);
				errorState = 1;
			}
			else if (*line != 0) {
				char* instbuffer = (char*)malloc(sizeof(char) * strlen(line) + 32);
				strcpy(instbuffer, line);
				if (instbuffer == NULL) {
					strcat(AsmErrorMessage, "ProcessAsmCode:malloc fail!\n");
					exit(1);
				}
				lines[lineCount] = instbuffer;
				lineMap[lineCount] = inputLineCount;
				lineCount++;
			}
		}
		line = strtok_s(NULL, "\n", &buf);
	}

	//处理.data
	currentState = 1;
	if (dataStartlineno == -1) {
		strcat(AsmErrorMessage, "ProcessAsmCode:Warning: data segment not found\n");
		return errorState;
	}
	bin.data.origin_pos = 0;
	currentbaseAddress = 0;
	bin.data.length = 0;
	bin.data.codes = (code*)malloc(sizeof(code) * validDataCount + 10);
	if (bin.data.codes == NULL) {
		strcat(AsmErrorMessage, "ProcessAsmCode:malloc fail!\n");
		exit(1);
	}
	code c = 0;
	int j = 0;
	int segmentEndLineno = 0;
	//先写text段
	if (textStartlineno < dataStartlineno) {
		segmentEndLineno = lineCount;
	}
	//先写data段
	else {
		segmentEndLineno = textStartlineno;
	}
	for (int i = dataStartlineno; i < segmentEndLineno; ++i) {
		if (j < oriCount && oriVertex[j].lineno <= i) {
			if (oriVertex[j].lineno == dataStartlineno) {
				bin.data.origin_pos = oriVertex[j].address;
			}
			currentbaseAddress = oriVertex[j].address;
			j++;
		}
		if (strlen(lines[i]) != 0) {
			if (dataFlag[i] == 0) {
				c = convertDataline_word(lines[i]);
			}
			else if (dataFlag[i] == 1) {
				c = convertDataline_half(lines[i]);
			}
			else if (dataFlag[i] == 2) {
				c = convertDataline_byte(lines[i]);
			}
			free(lines[i]);
			bin.data.codes[bin.data.length++] = c;
		}
	}

	//处理.text
	if (textStartlineno == -1) {
		strcat(AsmErrorMessage, "ProcessAsmCode:ERROR: .text segment not found\n");
		return 1;
	}
	bin.text.origin_pos = 0;
	bin.text.length = 0;
	currentbaseAddress = 0;
	currentState = 0;
	bin.text.codes = (code*)malloc(sizeof(code) * validTextCount + 10);
	if (bin.text.codes == NULL) {
		strcat(AsmErrorMessage, "ProcessAsmCode:malloc fail!\n");
		exit(1);
	}
	c = 0;
	//j = 0;
	//segmentEndLineno = 0;
	if (textStartlineno < dataStartlineno) {
		segmentEndLineno = dataStartlineno;
	}
	else {
		segmentEndLineno = lineCount;
	}
	for (int i = textStartlineno; i < segmentEndLineno; ++i) {
		if (strlen(lines[i]) != 0) {
			if (j < oriCount && oriVertex[j].lineno <= i) {
				if (oriVertex[j].lineno == textStartlineno) {
					bin.text.origin_pos = oriVertex[j].address;
				}
				currentbaseAddress = oriVertex[j].address;
				j++;
			}
			c = transToBinary(lines[i]);
			free(lines[i]);
			if (c == ERROR_CODE) {
				char errorbuffer[256];
				sprintf(errorbuffer, "ProcessAsmCode:ERROR: text segment line number %d\n message %s\n", lineMap[i], errorMessage);
				strcat(AsmErrorMessage, errorbuffer);
				errorState = 1;
			}
			bin.text.codes[bin.text.length++] = c;
		}
	}

	return errorState;
}
//汇编总逻辑接口
int  compile(char* text) {

	if (initlablesStack()) {
		return 1;
	}
	if (loadInstructions() == -1) {
		strcat(AsmErrorMessage, "compile: load instruction file fail\n");
		return 1;
	}

	Asmflag = 0;

	AsmErrorMessage[0] = 0;
	errorMessage[0] = 0;

	lineCount = 0;
	inputLineCount = 0;

	oriCount = 0;
	currentState = 0;
	currentbaseAddress = 0;

	textStartlineno = -1;
	dataStartlineno = -1;
	validTextCount = 0;
	validDataCount = 0;

	int r = ProcessAsmCode(text);
	//output();
	if (r == 1) {
		strcat(AsmErrorMessage, "compile:compile terminate.\n");
		return 1;
	}

	//destrylabelStack();
	strcpy(AsmErrorMessage, "compile:compile successfully.\n");
	Asmflag = 1;
	return 0;
}


//读取文件
bool readFileToString(string filename, string& fileData)
{
	ifstream file(filename.c_str(), ifstream::binary);

	if (file)
	{
		file.seekg(0, file.end);
		const int file_size = file.tellg();
		char* file_buf = new char[file_size + 1];
		memset(file_buf, 0, file_size + 1);
		file.seekg(0, ios::beg);
		file.read(file_buf, file_size);
		if (file)
		{
			fileData.append(file_buf);
		}
		else
		{
			std::cout << "error: only " << file.gcount() << " could be read";
			fileData.append(file_buf);
			return false;
		}
		file.close();
		delete[]file_buf;
	}
	else
	{
		return false;
	}

	return true;
}
//todo
//输出文件 
bool outputCode(string codeFile) {
	//.text
	string outText;
	for (int i = 0; i < bin.text.length; i++) {
		char binary[33];
		char hex[33];
		code decimal = bin.text.codes[i];
		_itoa(decimal, hex, 16);

		cout << hex << endl;

		/*_itoa(decimal, binary, 2);
		int n = strlen(binary);
		char str[33];
		for (int i = 0; i < 32 - n; i++) {
			str[i] = '0';
		}
		str[32 - n] = '\0';
		strcat(str, binary);*/
		int n = strlen(hex);
		char str[9];
		for (int i = 0; i < 8 - n; i++) {
			str[i] = '0';
		}
		str[8 - n] = '\0';
		strcat(str, hex);
		outText += str;
	}

	//.data
	string outData;
	for (int i = 0; i < bin.data.length; i++) {
		char binary[33];
		char hex[33];
		code decimal = bin.data.codes[i];
		_itoa(decimal, hex, 16);
		/*_itoa(decimal, binary, 2);
		int n = strlen(binary);
		char str[33];
		for (int i = 0; i < 32 - n; i++) {
			str[i] = '0';
		}
		str[32 - n] = '\0';
		strcat(str, binary);*/
		int n = strlen(hex);
		char str[9];
		for (int i = 0; i < 8 - n; i++) {
			str[i] = '0';
		}
		str[8 - n] = '\0';
		strcat(str, hex);
		outData += str;
	}

	//.head
	string outBody;
	outBody = outText + outData;
	string outHead;
	int offset = outBody.length();
	offset += 12;
	string _offset = to_string(offset);
	int n = _offset.length();
	for (int i = 0; i < 11 - n; i++) {
		outHead += '0';
	}
	outHead += _offset;
	outHead += " ";

	outBody = outputCodeProcess(outBody,8);
	ofstream codefile(codeFile.c_str(), ios::binary | ios::out);
	if (!(codefile.is_open()))
	{
		cout << "打开文件失败" << endl;
		return 0;
	}
	if (codefile) {
		codefile << "memory_initialization_radix=16;\n";
		codefile << "memory_initialization_vector=\n";
		codefile << outBody;
	}

}



//test 函数
int test_regsName2regsNum(char* instruction){
    regsName2regsNum(instruction);
    return 0;
}
code test_RtypeTransfer(int rd, int rs, int rt) {
	code r = 0;
	r |= 24;
	r |= rd << 11;
	r |= rt << 16;
	r |= rs << 21;
	r |= 16 << 26;
	return r;
}
//十进制或十六进制字符串->无符号整数 0x021->33
int test_DecHex2Int(char* str) {
	cout<<DecHex2Int(str);
	return 0;
}
//测试检查标签名合法性
void test_checkLabelName(char* name) {
	cout<<checkLabelName(name);
}
void test_removeSpace(char* s) {
	removeSpace(s);
	cout << s;
}
void test_data2code(char cbuffer[], code c, int count) {
	char* wordbuffer = (char*)malloc(sizeof(char) * 24);
	if (wordbuffer == NULL) {
		strcat(AsmErrorMessage, "data2code：malloc fail!\n");
		exit(1);
	}
	memcpy(&c, cbuffer, sizeof(char) * count);
	sprintf(wordbuffer, "%x", c);
	char* temp = new char[11];
	char tmp[11] = "0x";
	strcat(tmp, wordbuffer);
	strcpy(temp, tmp);
	cout << temp;
}