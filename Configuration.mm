/*
  Disseminate, keyboard broadcaster
  Copyright (C) 2016  Jan Erik Hanssen

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "Configuration.h"
#include "Helpers.h"
#include "ui_Configuration.h"
#include <QInputDialog>
#include <CocoaUtils.h>
#include <QtMac>
#include <QDebug>
#import <Cocoa/Cocoa.h>

Configuration::Configuration(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::Configuration)
{
    ui->setupUi(this);
    connect(ui->selectApplication, &QPushButton::clicked, this, &Configuration::selectApplication);
    connect(ui->addClient, &QPushButton::clicked, this, &Configuration::addClient);
    connect(ui->removeClient, &QPushButton::clicked, this, &Configuration::removeClients);

    connect(this, &Configuration::accepted, this, &Configuration::emitItemSelected);
}

Configuration::~Configuration()
{
    delete ui;
}

void Configuration::selectApplication()
{
    ScopedPool pool;

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowedFileTypes:[[NSArray arrayWithObjects:@"app", nil] autorelease]];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setTreatsFilePackagesAsDirectories:NO];
    [openPanel setTitle:@"Select Application"];
    [openPanel setDirectoryURL:[NSURL URLWithString:@"/Applications"]];

    NSInteger result = [openPanel runModal];

    if (result == NSFileHandlingPanelOKButton) {
        NSArray *URLs = [openPanel URLs];
        for (NSURL *URL in URLs) {
            const QString path = QString::fromNSString(URL.path);

            ui->application->setText(path);

            NSBundle* bundle = [[NSBundle bundleWithURL:URL] autorelease];
            if (bundle) {
                NSString* appPath = [bundle bundlePath];
                if (appPath) {
                    NSImage* appIcon = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
                    if (appIcon) {
                        NSRect iconRect = NSMakeRect(0, 0, appIcon.size.width, appIcon.size.height);
                        CGImageRef cgIcon = [appIcon CGImageForProposedRect:&iconRect context:NULL hints:nil];
                        ui->application->setIcon(QtMac::fromCGImageRef(cgIcon));
                    }
                }
            }
        }
    }
}

void Configuration::addClient()
{
    const QString client = QInputDialog::getText(this, "Add Client", "Add Client");
    if (!client.isEmpty()) {
        if (!helpers::contains(ui->clients, client)) {
            ui->clients->addItem(client);
        }
    }
}

void Configuration::removeClients()
{
    for (auto& item : ui->clients->selectedItems()) {
        delete item;
    }
}

void Configuration::emitItemSelected()
{
    Item item;
    item.name = ui->name->text();
    item.appPath = ui->application->text();
    item.appIcon = ui->application->icon();

    const QListWidget* listWidget = ui->clients;
    for(int i = 0; i < listWidget->count(); ++i) {
        QListWidgetItem* witem = listWidget->item(i);
        item.clients.append(witem->text());
    }

    emit itemSelected(item);
}

void Configuration::setItem(const Item& item)
{
    ui->name->setText(item.name);
    ui->name->setDisabled(true);
    ui->application->setText(item.appPath);
    ui->application->setIcon(item.appIcon);

    removeClients();
    for (const auto& c : item.clients) {
        ui->clients->addItem(c);
    }
}
