#include "KeyInput.h"
#include "Utils.h"
#include "ui_KeyInput.h"

KeyInput::KeyInput(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::KeyInput),
    currentKey(0)
{
    ui->setupUi(this);
    connect(this, &KeyInput::accepted, this, &KeyInput::emitKeyAdded);
    capturing = capture::startReadKey([this](int64_t key) {
            currentKey = key;
            updateKey();
        });
}

KeyInput::~KeyInput()
{
    capture::stopReadKey();
    delete ui;
}

void KeyInput::emitKeyAdded()
{
    if (currentKey)
        emit keyAdded(currentKey);
}

void KeyInput::updateKey()
{
    ui->keyEdit->setText(QString::number(currentKey));
}
