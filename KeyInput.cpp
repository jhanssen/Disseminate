#include "KeyInput.h"
#include "Helpers.h"
#include "Utils.h"
#include "ui_KeyInput.h"

KeyInput::KeyInput(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::KeyInput),
    currentKey(0), currentFlags(0)
{
    ui->setupUi(this);
    connect(this, &KeyInput::accepted, this, &KeyInput::emitKeyAdded);
    capturing = broadcast::startReadKey([this](int64_t key, uint64_t flags) {
            currentKey = key;
            currentFlags = flags;
            updateKey();
        });
}

KeyInput::~KeyInput()
{
    broadcast::stopReadKey();
    delete ui;
}

void KeyInput::emitKeyAdded()
{
    if (currentKey || currentFlags)
        emit keyAdded(currentKey, currentFlags);
}

void KeyInput::updateKey()
{
    ui->keyEdit->setText(helpers::keyToQString(currentKey, currentFlags));
}

void KeyInput::keyPressEvent(QKeyEvent*)
{
}

void KeyInput::keyReleaseEvent(QKeyEvent*)
{
}
