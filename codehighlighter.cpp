#include "codehighlighter.h"

CodeHighlighter::CodeHighlighter(QTextDocument *parent)
    : QSyntaxHighlighter(parent)
{
    // 设置关键字的正则表达式
    keywordPattern = QRegExp("\\b(break|continue|if|int|string|return|void|while)\\b");

    // 设置关键字的显示格式
    keywordFormat.setForeground(Qt::red);
    commentFormat.setForeground(Qt::green);
}

void CodeHighlighter::highlightBlock(const QString &text)
{
    // 高亮关键字
    int index = keywordPattern.indexIn(text);
    while (index >= 0) {
        setFormat(index, keywordPattern.matchedLength(), keywordFormat);
        index = keywordPattern.indexIn(text, index + keywordPattern.matchedLength());
    }

    // 高亮注释
    QRegExp commentPattern("//[^\n]*");
    index = commentPattern.indexIn(text);
    while (index >= 0) {
        setFormat(index, commentPattern.matchedLength(), commentFormat);
        index = commentPattern.indexIn(text, index + commentPattern.matchedLength());
    }
}
