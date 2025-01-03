#ifndef CODEHIGHLIGHTER_H
#define CODEHIGHLIGHTER_H

#include <QSyntaxHighlighter>
#include <QTextCharFormat>
#include <QRegExp>

class CodeHighlighter : public QSyntaxHighlighter
{
public:
    CodeHighlighter(QTextDocument *parent = nullptr);

protected:
    void highlightBlock(const QString &text) override;

private:
    QRegExp keywordPattern;
    QRegExp bracketPattern;
    QTextCharFormat keywordFormat;
    QTextCharFormat commentFormat;
    QTextCharFormat bracketFormat;
};

#endif // CODEHIGHLIGHTER_H
