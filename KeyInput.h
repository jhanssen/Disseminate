#ifndef KEYINPUT_H
#define KEYINPUT_H

#include <QDialog>

namespace Ui {
class KeyInput;
}

class KeyInput : public QDialog
{
    Q_OBJECT

public:
    explicit KeyInput(QWidget *parent = 0);
    ~KeyInput();

    bool valid() const { return capturing; }

protected:
    void keyPressEvent(QKeyEvent*);
    void keyReleaseEvent(QKeyEvent*);

signals:
    void keyAdded(int64_t key, uint64_t mask);

private slots:
    void emitKeyAdded();

private:
    void updateKey();

private:
    Ui::KeyInput *ui;
    int64_t currentKey;
    uint64_t currentFlags;
    bool capturing;
};

#endif // KEYINPUT_H
