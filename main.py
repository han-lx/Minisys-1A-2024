import sys
from lexer import tokenize
from parser import parse
from IRGenerator import IRGenerator
from IROptimizer import IROptimizer
from asm.ASMGenerator import ASMGenerator

def compile_file():
    """编译MiniC源文件"""
    try:
        # 读取源文件
        with open('test.c', 'r', encoding='utf-8') as f:
            source = f.read()
        if not source.strip():
            raise Exception("Source code is empty!")
            
        # 词法分析
        tokens = tokenize(source)
        print(f"Tokenization done. Received {len(tokens)} tokens.")
        
        # 语法分析
        ast = parse(source)
        if not ast:
            raise Exception("AST root is null.")
        print("Parsing done.")
        
        # 生成中间代码
        ir_gen = IRGenerator(ast)
        
        # 输出原始IR
        with open('test_py.raw.ir', 'w', encoding='utf-8') as f:
            f.write(ir_gen.to_ir_string())
            
        # IR优化
        ir_optimizer = IROptimizer(ir_gen)
        
        # 输出优化后的IR
        with open('test_py.opt.ir', 'w', encoding='utf-8') as f:
            f.write(ir_gen.to_ir_string())
            
        # 生成汇编代码
        asm_gen = ASMGenerator(ir_gen)
        
        # 输出汇编代码
        with open('test_py.asm', 'w', encoding='utf-8') as f:
            f.write(asm_gen.to_assembly())
        
        print("Assembly generation done.") 
        
    except Exception as ex:
        import traceback
        print("错误发生在:")
        print(traceback.format_exc())
        print(f"[Error] {str(ex)}")
        sys.exit(1)

if __name__ == "__main__":
    compile_file() 