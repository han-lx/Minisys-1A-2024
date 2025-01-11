#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <cassert>
#include <iomanip>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <regex>
#include <cstdlib>  
using namespace std;

const uint32_t BIOS_START = 0x00000000;
const uint32_t BIOS_END = 0x00000499;
const uint32_t USER_START = 0x00000500;
const uint32_t USER_END = 0x00005499;
const uint32_t INTERRUPT_HANDLER_START = 0x0000F500;
const uint32_t INTERRUPT_HANDLER_END = 0x0000FFFF;


void padUnusedRegions(ofstream& outputFile, uint32_t currentOffset, uint32_t nextStart) {
    while (currentOffset < nextStart) {
        outputFile << "00000000," << endl;
        currentOffset += 4;
    }
}

uint32_t processCOEFile(const string& filePath, ofstream& outputFile, uint32_t startOffset, uint32_t endOffset) {
    ifstream inputFile(filePath);
    if (!inputFile.is_open()) {
        throw runtime_error("Failed to open file: " + filePath);
    }

    string line;
    while (getline(inputFile, line)) {
        if (line.find("memory_initialization_vector=") != string::npos) {
            break;
        }
    }

    while (getline(inputFile, line)) {
        line = line.substr(0, line.find(';'));
        if (line.empty()) continue;

        if (startOffset > endOffset) {
            throw runtime_error("Segment overflow for file: " + filePath);
        }

        outputFile << hex << setw(8) << setfill('0') << line << endl;
        startOffset += 4;
    }

    inputFile.close();
    return startOffset;
}


void generateLinkedCOE(const vector<string>& filePaths, const string& outputPath) {
    ofstream outputFile(outputPath);
    if (!outputFile.is_open()) {
        throw runtime_error("Failed to open output file: " + outputPath);
    }

    outputFile << "memory_initialization_radix=16;\nmemory_initialization_vector=" << endl;

    uint32_t currentOffset = BIOS_START;
    currentOffset = processCOEFile(filePaths[0], outputFile, currentOffset, BIOS_END);

    padUnusedRegions(outputFile, currentOffset, USER_START);
    currentOffset = processCOEFile(filePaths[1], outputFile, USER_START, USER_END);

    padUnusedRegions(outputFile, currentOffset, INTERRUPT_HANDLER_START);
    currentOffset = processCOEFile(filePaths[2], outputFile, INTERRUPT_HANDLER_START, INTERRUPT_HANDLER_END);

    padUnusedRegions(outputFile, currentOffset, INTERRUPT_HANDLER_END + 1);

    outputFile.close();

    fstream inFile(outputPath, ios::in); // Open file for reading
    if (!inFile.is_open()) {
        throw runtime_error("Failed to reopen output file for modification: " + outputPath);
    }

    vector<string> lines;
    string line;
    while (getline(inFile, line)) {
        lines.push_back(line);
    }
    inFile.close();

    for (int i = lines.size() - 1; i >= 0; --i) {
        size_t pos = lines[i].find_last_of(",");
        if (pos != string::npos) {
            lines[i][pos] = ';';
            break;
        }
    }

    ofstream outFile(outputPath, ios::trunc);
    if (!outFile.is_open()) {
        throw runtime_error("Failed to open output file for writing: " + outputPath);
    }

    for (const auto& modifiedLine : lines) {
        outFile << modifiedLine << endl;
    }

    outFile.close();
}

int main() {
    try {
        vector<string> filePaths = { "C:/Users/lx/Desktop/bios.coe", "C:/Users/lx/Desktop/test_py.coe", "C:/Users/lx/Desktop/interrupt.coe" };
        generateLinkedCOE(filePaths, "C:/Users/lx/Desktop/linked_output.coe");

        cout << "Linking completed. Output file: linked_output.coe" << endl;
    }
    catch (const exception& e) {
        cerr << "Error: " << e.what() << endl;
    }

    return 0;
}
