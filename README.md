# Minisys-1A-2024
东南大学计算机系统综合课程设计

## 项目简介

本项目是一个基于 MiniC 语言的编译器实现，涵盖了词法分析、语法分析、中间代码生成、代码优化以及汇编代码生成等完整的编译过程。

## 功能说明

- **词法分析**：使用 PLY 库对 MiniC 源代码进行词法分析，生成 Token 流。
- **语法分析**：使用 PLY 构建 LALR(1) 语法分析器，生成抽象语法树（AST）。
- **中间代码生成**：遍历 AST，生成中间表示（IR），包括四元式和基本块划分。
- **代码优化**：对中间代码进行优化，如常量折叠、死代码消除等，提升代码执行效率。
- **汇编代码生成**：将优化后的中间代码翻译为 Minisys-1A 汇编指令，可在模拟器上运行。

## 使用方法

1. **克隆仓库**

   ```bash
   git clone https://github.com/yourusername/Minisys-1A-2024.git
   ```

2. **安装依赖**

   ```bash
   pip install -r requirements.txt
   ```

3. **编译并运行**

   ```bash
   python main.py
   ```

   默认情况下，`main.py` 将编译 `test.c` 文件。您可以修改 `main.py` 以编译其他源文件。

## 项目结构

- `lexer.py`：词法分析器，定义了 MiniC 语言的词法规则。
- `parser.py`：语法分析器，基于 PLY 的 YACC 构建，生成 AST。
- `IRGenerator.py`：中间代码生成器，将 AST 转换为四元式表示。
- `IROptimizer.py`：中间代码优化器，对四元式进行优化处理。
- `asm/ASMGenerator.py`：汇编代码生成器，将优化后的中间代码转换为汇编指令。
- `test.c`：示例 MiniC 源代码文件，用于测试编译器功能。
- `requirements.txt`：项目所需的 Python 包列表。

## 贡献指南

欢迎对本项目提出问题（Issue）和贡献代码（Pull Request）。在提交流程前，请确保您的代码符合项目的编码规范，并进行了充分的测试。

## 许可证

本项目采用 [MIT 许可证](LICENSE)。
