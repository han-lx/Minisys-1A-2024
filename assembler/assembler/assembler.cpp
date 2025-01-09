#define _CRT_SECURE_NO_WARNINGS
#include <iostream>
#include "myAssembler.h"
using namespace std;
string decimalToBinary(int decimal) {
    if (decimal == 0) {
        return "0";
    }
    string binary;
    while (decimal > 0) {
        binary = to_string(decimal % 2) + binary;
        decimal /= 2;
    }
    return binary;
}
//测试函数
void test() {
    //test_regsName2regsNum
    /*{
        char instruction[] = "add $t0, $t1, $t2";  // 示例指令
        std::cout << "Original instruction: " << instruction << std::endl;
        int result = test_regsName2regsNum(instruction); // 测试函数
        if (result == 0) {
            std::cout << "Updated instruction: " << instruction << std::endl;
    }*/
    //test_RtypeTransfer
    /*{
        code c;
        c = test_RtypeTransfer( 0, 16, 0);
        cout << decimalToBinary(c) << endl;
    }*/
    //test_DecHex2Int
    /*{
        char str[] = "0x021";
        test_DecHex2Int(str);
    }*/
    //test_checkLabelName
    /*{
        char str[] = "abc";
        test_checkLabelName(str);
        cout << endl<<getErrorMessage();
    }*/
    //test_removeSpace(char* s)
    //{
    //    char testStr1[] = "   Hello   World!   ";  // 包含多个空格
    //    char testStr2[] = "NoSpaces";              // 没有空格
    //    char testStr3[] = "   Leading and trailing spaces   ";  // 前后空格
    //    test_removeSpace(testStr1);
    //    cout << endl;
    //    test_removeSpace(testStr2);
    //    cout << endl;
    //    test_removeSpace(testStr3);
    //    cout << endl;
    //}
    //test_data2code
    {
        char testBuffer1[] = "1234";  // 字符数组
        test_data2code(testBuffer1, 0, strlen(testBuffer1));
    }
    
}
int main() {
    //test();

    string data;
    string src1 = "C:/Users/lx/Desktop/buzzer.asm";

    char out[50];
    strcpy_s(out, "C:/Users/lx/Desktop/buzzer.asm");
    strtok(out, ".");
    strcat_s(out, ".coe");
    if (readFileToString(src1, data))
    {
        cout << "File data is:\r\n" << data << endl;
    }
    else
    {
        cout << "Failed to open the file, please check the file path." << endl;
    }
    char compileBuffer[65536];
    strcpy_s(compileBuffer, data.c_str());
    if (compile(compileBuffer) == 1) {
        getAsmErrorMessage("Asmlog.txt");
    }
    else {
        getAsmErrorMessage("Asmlog.txt");

        outputCode(out);
    }
    return 0;
}