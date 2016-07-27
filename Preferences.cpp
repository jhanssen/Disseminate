#include "Preferences.h"
#include "ui_Preferences.h"
#include <QInputDialog>

Preferences::Preferences(QWidget *parent, const Config& cfg) :
    QDialog(parent),
    ui(new Ui::Preferences)
{
    ui->setupUi(this);
    for (const auto& str : cfg.automaticWindows) {
        ui->windowList->addItem(str);
    }

    connect(this, &Preferences::accepted, this, &Preferences::emitConfigChanged);
    connect(ui->addWindow, &QPushButton::clicked, this, &Preferences::addWindow);
    connect(ui->removeWindow, &QPushButton::clicked, this, &Preferences::removeWindow);
}

Preferences::~Preferences()
{
    delete ui;
}

void Preferences::emitConfigChanged()
{
    Config cfg;
    const int windowCount = ui->windowList->count();
    for (int i = 0; i < windowCount; ++i) {
        QListWidgetItem* item = ui->windowList->item(i);
        cfg.automaticWindows.append(item->text());
    }
    emit configChanged(cfg);
}

void Preferences::addWindow()
{
    const QString win = QInputDialog::getText(this, "Window Matching", "Add Window Matching");
    if (!win.isEmpty()) {
        if (ui->windowList->findItems(win, Qt::MatchFixedString).isEmpty()) {
            ui->windowList->addItem(win);
        }
    }
}

void Preferences::removeWindow()
{
    const auto& items = ui->windowList->selectedItems();
    for (auto& item : items) {
        delete item;
    }
}
