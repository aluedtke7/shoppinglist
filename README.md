# Shoppinglist with Flutter and PocketBase

## Overview
The purpose of this app is to maintain a shoppinglist that can be used by more than one person.
In our family, we all use this app to inform the others about the goods that are wanted. If someone goes shopping, 
he/she can buy the goods for all family members.

The backend software PocketBase informs all running instances of the app about changes in the
list. So, if you're inside a shop, you will see also articles that are newly put in the list by other members.

This app needs a PocketBase backend, running somewhere. PocketBase is a Firebase clone in one single binary.
More infos on [the PocketBase homepage](https://pocketbase.io). On that page is a good description to run PocketBase 
on [fly.io](https://github.com/pocketbase/pocketbase/discussions/537) in the discussion area. There are some chapters 
about fly.io further down below.

### Features
- several themes with custom options
- localization (English and German)
- works on Linux, Android, Windows, iOS, MacOS (Web version lacks realtime events, see [caveats](#caveats))

### Screenshots
<img src="./screenshots/login.png" title="The login page" width="280">
<img src="./screenshots/dark_theme.png" title="A dark theme" width="280">
<img src="./screenshots/shoppinglist-1.png" title="The shopping list" width="280">
<img src="./screenshots/shoppinglist-2.png" title="Swipe right for editing" width="280">
<img src="./screenshots/shoppinglist-3.png" title="Swipe left for marking" width="280">
<img src="./screenshots/shoppinglist-4.png" title="2 articles bought" width="280">
<img src="./screenshots/search_article.png" title="Search article" width="280">
<img src="./screenshots/drawer_open.png" title="Open drawer" width="280">
<img src="./screenshots/end_shopping.png" title="End shopping" width="280">
<img src="./screenshots/article_list.png" title="Article list" width="280">
<img src="./screenshots/logout.png" title="Logout" width="280">

Here are some tips for the shopping list:

- you can mark an article as bought either by swiping left and press the checkmark icon
or by double clicking the article itself
- click on the plus or minus sign to change the quantity of that article
- bought articles are placed at the end of the list to have a clearer view
- articles are grouped by shop and sorted alphabetically
- in the search dialog, a new article can be be added by pressing the plus sign

## Technical description
There is only one database table 'shoppinglist' that is used in this app. This table (or collection)
has the following fields that must be created beforehand:

- `active`  : Bool
- `amount`  : Number, Min=0, Max=100
- `bought`  : Bool
- `article` : Plain text, Min length=1, Max length=120, Nonempty, Unique
- `shop`    : Plain text, Max length=80

There is also a schema file in JSON format (`pb_schema.json`) that can be imported in PocketBase to 
create this collection.

## Caveats
PocketBase is offering realtime events to inform the client (shoppinglist app) about data changes. Unfortunately, 
this doesn't work with Flutter Web. More details about the technical facts can be found in 
[this thread in the discussion board](https://github.com/pocketbase/pocketbase/discussions/1485) of PocketBase.

## Get it working
### Install / deploy PocketBase
Proceed as follows:

1. deploy or install PocketBase (local is fine)
1. open the admin page of PocketBase (create PocketBase admin user on the fly)
1. import `pb_schema.json` to create the shoppinglist collection (via "Sync - Import Collection")
1. create users with email and password. Mark them as verified and give them a **NAME**. This name is visible in the app.
1. enter some data in the shoppinglist collection or do it later in the app

### Compile / run Shoppinglist
I assume, that Flutter is installed on your machine and that `flutter doctor` doesn't show errors for the platform
your gonna use.

1. run **`flutter run`** to start the application with a local installed PocketBase
1. if your PocketBase instance is not on localhost, you have to run
 **`flutter run --dart-define=SHOPPINGLIST_HOST=https://YOUR-POCKETBASE-DOMAIN.com`**
1. to create an Android app i.e. run **`flutter build apk`**
1. if your PocketBase instance is not on localhost, you have to run 
**`flutter build apk --dart-define=SHOPPINGLIST_HOST=https://YOUR-POCKETBASE-DOMAIN.com`**
1. inside the app, login with email and password

That's it. Have fun and go shopping!

> **Important**
> -------------
> If you run PocketBase locally and want to access it i.e. from the Android Emulator, you need to start
PocketBase like this:
>
>    `> pocketbase serve --http 0.0.0.0:8090`
>
>This ensures, that PocketBase will listen on all addresses. Furthermore, you need to set the environment variable 
`SHOPPINGLIST_HOST` with the correct ip-address of your host machine like `http://192.168.0.52`. The address depends
on your network and you should look it up with tools like `ip a`, `ipconfig` or `ifconfig`.

## Create release builds
To create a release build that uses the right PocketBase url, you have to set a command line option to supply the environment variable to flutter:

    > flutter build apk --dart-define=SHOPPINGLIST_HOST=https://YOUR-POCKETBASE-DOMAIN.com

## Using Visual Studio Code
In order to have the right environment variable when running or debugging the app in VSCode, you
have to create a launch configuration `.vscode/launch.json` and have a configuration like this:

    {
        "version": "0.2.0",
        "configurations": [
            {
                "name": "shoppinglist",
                "request": "launch",
                "type": "dart",
                // Arguments to be passed to the Flutter app
                "args": [
                    "--dart-define",
                    "SHOPPINGLIST_HOST=https://YOUR-POCKETBASE-DOMAIN.com"
                ]
            },
        ]
    }

## Localization
The app uses the `Intl` package to maintain different localizations. Run the following command, if you change 
the content of the `./lib/l10n/*.arb` files:

    > flutter gen-l10n

This will update the files in `.dart_tool/flutter_gen/gen_l10n`.

## PocketBase running on fly.io
In the following chapters I show some useful commands to help you manage PocketBase on fly.io. I assume, that you're in the folder where the `Dockerfile` and the file `fly.toml` reside. 

### Inspect container
If you want to see what is currently in the container:

    > flyctl ssh console
    # ls -l /pb/pb_data

### Backup
Make a local backup of the database file:

    > flyctl ssh sftp get /pb/pb_data/data.db ./data.db

### Restore
Restore a database backup on fly.io:

    > flyctl ssh sftp shell
    >> put ./LOCAL-PATH-WITH-DB/data.db /pb/pb_data/data.db

After that, you should restart PocketBase, in order to use the restored database:

    > flyctl apps restart YOUR_APPLICATION_NAME

### Deploy new PocketBase version
You have to update the `fly.toml` in respect of the PocketBase version (`PB_VERSION`). After doing that, run

    > flyctl deploy

Your database will not be affected and remains as it is.
