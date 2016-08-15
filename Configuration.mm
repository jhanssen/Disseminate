#include "Configuration.h"
#include "Helpers.h"
#include "ui_Configuration.h"
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
