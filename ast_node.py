from typing import List, Optional

class ASTNode:
    """语法树节点"""
    def __init__(self, name: str, type_: str, literal: str, lineno: int = 0, lexpos: int = 0):
        self.name = name  # 节点名
        self.type = type_  # 节点类型: 'token' 或 'nonterminal'
        self.literal = literal  # 字面量
        self.children: List[ASTNode] = []
        self.lineno = lineno  # 添加行号
        self.lexpos = lexpos  # 添加位置信息
    
    def add_child(self, node: Optional['ASTNode']):
        """添加子节点,允许None"""
        if node is not None:
            self.children.append(node)
        
    def match(self, rhs: str) -> bool:
        """判断子节点name是否匹配某串"""
        seq = rhs.strip().split(' ')
        if len(seq) == len(self.children):
            return all(seq[i] == self.children[i].name for i in range(len(seq)))
        return False

    def __getitem__(self, i: int) -> 'ASTNode':
        """one-based 访问子节点"""
        assert 1 <= i <= len(self.children), f'$i超出范围：{i} out-of {len(self.children)}'
        return self.children[i-1]

def visualize_ast(root: ASTNode, save_png: bool = True):
    """可视化语法树"""
    import graphviz
    
    # 创建有向图,设置为LR方向(从左到右)和方形节点
    dot = graphviz.Digraph()
    dot.attr(rankdir='LR')  # 从左到右布局
    dot.attr('node', shape='box')  # 使用方形节点
    
    def add_nodes_edges(node: ASTNode, parent_id: Optional[str] = None):
        node_id = str(id(node))
        
        # 设置节点样式
        if node.type == 'token':
            # token节点显示名称和值
            label = f'{node.name}\n{node.literal}'
            dot.node(node_id, label, style='filled', fillcolor='lightgrey')
        else:
            # 非终结符节点只显示名称
            label = node.name
            dot.node(node_id, label)
            
        # 添加边
        if parent_id:
            dot.edge(parent_id, node_id)
            
        # 递归处理子节点
        for child in node.children:
            add_nodes_edges(child, node_id)
            
    # 构建图
    add_nodes_edges(root)
    
    # 设置图形属性
    dot.attr(bgcolor='white')  # 白色背景
    dot.attr('edge', color='#777777')  # 灰色边
    dot.attr('node', style='filled', fillcolor='white',  # 节点样式
            color='#333333', fontname='Consolas')
    
    # 渲染图形
    dot.render('ast', view=True, format='png' if save_png else 'pdf',
              cleanup=True)  # cleanup=True 删除中间文件 