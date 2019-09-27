
#include "common.h"
#include "menu.h"

@implementation AvnMenu
@end

@implementation AvnMenuItem
{
    AvnAppMenuItem* _item;
}

- (id) initWithAvnAppMenuItem: (AvnAppMenuItem*)menuItem
{
    if(self != nil)
    {
        _item = menuItem;
        self = [super initWithTitle:@""
                             action:@selector(didSelectItem:)
                      keyEquivalent:@""];
        
        [self setEnabled:YES];
        
        [self setTarget:self];
    }
    
    return self;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if([self submenu] != nil)
    {
        return YES;
    }
    
    return _item->EvaluateItemEnabled();
}

- (void)didSelectItem:(nullable id)sender
{
    _item->RaiseOnClicked();
}
@end

AvnAppMenuItem::AvnAppMenuItem(bool isSeperator)
{
    _isSeperator = isSeperator;
    
    if(isSeperator)
    {
        _native = [NSMenuItem separatorItem];
    }
    else
    {
        _native = [[AvnMenuItem alloc] initWithAvnAppMenuItem: this];
    }
    
    _callback = nullptr;
}

NSMenuItem* AvnAppMenuItem::GetNative()
{
    return _native;
}

HRESULT AvnAppMenuItem::SetSubMenu (IAvnAppMenu* menu)
{
    auto nsMenu = dynamic_cast<AvnAppMenu*>(menu)->GetNative();
    
    [_native setSubmenu: nsMenu];
    
    return S_OK;
}

HRESULT AvnAppMenuItem::SetTitle (void* utf8String)
{
    [_native setTitle:[NSString stringWithUTF8String:(const char*)utf8String]];
    
    return S_OK;
}

HRESULT AvnAppMenuItem::SetGesture (void* key, AvnInputModifiers modifiers)
{
    NSEventModifierFlags flags = 0;
    
    if (modifiers & Control)
        flags |= NSEventModifierFlagControl;
    if (modifiers & Shift)
        flags |= NSEventModifierFlagShift;
    if (modifiers & Alt)
        flags |= NSEventModifierFlagOption;
    if (modifiers & Windows)
        flags |= NSEventModifierFlagCommand;
    
    [_native setKeyEquivalent:[NSString stringWithUTF8String:(const char*)key]];
    [_native setKeyEquivalentModifierMask:flags];
    
    return S_OK;
}

HRESULT AvnAppMenuItem::SetAction (IAvnPredicateCallback* predicate, IAvnActionCallback* callback)
{
    _predicate = predicate;
    _callback = callback;
    return S_OK;
}

bool AvnAppMenuItem::EvaluateItemEnabled()
{
    if(_predicate != nullptr)
    {
        auto result = _predicate->Evaluate ();
        
        return result;
    }
    
    return false;
}

void AvnAppMenuItem::RaiseOnClicked()
{
    if(_callback != nullptr)
    {
        _callback->Run();
    }
}

AvnAppMenu::AvnAppMenu()
{
    _native = [AvnMenu new];
}

AvnAppMenu::AvnAppMenu(AvnMenu* native)
{
    _native = native;
}

AvnMenu* AvnAppMenu::GetNative()
{
    return _native;
}

HRESULT AvnAppMenu::AddItem (IAvnAppMenuItem* item)
{
    auto avnMenuItem = dynamic_cast<AvnAppMenuItem*>(item);
    
    if(avnMenuItem != nullptr)
    {
        [_native addItem: avnMenuItem->GetNative()];
    }
    
    return S_OK;
}

HRESULT AvnAppMenu::RemoveItem (IAvnAppMenuItem* item)
{
    auto avnMenuItem = dynamic_cast<AvnAppMenuItem*>(item);
    
    if(avnMenuItem != nullptr)
    {
        [_native removeItem:avnMenuItem->GetNative()];
    }
    
    return S_OK;
}

HRESULT AvnAppMenu::SetTitle (void* utf8String)
{
    if (utf8String != nullptr)
    {
        [_native setTitle:[NSString stringWithUTF8String:(const char*)utf8String]];
    }
    
    return S_OK;
}

HRESULT AvnAppMenu::Clear()
{
    [_native removeAllItems];
    return S_OK;
}

extern IAvnAppMenu* CreateAppMenu()
{
    @autoreleasepool
    {
        id menuBar = [NSMenu new];
        return new AvnAppMenu(menuBar);
    }
}

extern IAvnAppMenuItem* CreateAppMenuItem()
{
    @autoreleasepool
    {
        return new AvnAppMenuItem(false);
    }
}

extern IAvnAppMenuItem* CreateAppMenuItemSeperator()
{
    @autoreleasepool
    {
        return new AvnAppMenuItem(true);
    }
}

static IAvnAppMenu* s_appMenu = nullptr;
static NSMenuItem* s_appMenuItem = nullptr;

extern void SetAppMenu (IAvnAppMenu* appMenu)
{
    s_appMenu = appMenu;
    
    if(s_appMenu != nullptr)
    {
        auto nativeMenu = dynamic_cast<AvnAppMenu*>(s_appMenu);
        
        s_appMenuItem = [nativeMenu->GetNative() itemAtIndex:0];
    }
    else
    {
        s_appMenuItem = nullptr;
    }
}

extern IAvnAppMenu* GetAppMenu ()
{
    return s_appMenu;
}

extern NSMenuItem* GetAppMenuItem ()
{
    return s_appMenuItem;
}

