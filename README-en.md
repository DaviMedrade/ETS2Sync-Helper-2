# ETS2Sync Helper
[VERSÃO EM PORTUGUÊS](README.md)

[LICENSE](LICENSE.md)

This app synchronizes the job list on Euro Truck Simulator 2, in order to make it easier to organize a convoy on Multiplayer.

## Download
Languages: Brazilian Portuguese, European Portuguese, English, German, and Spanish.
http://files.dsantosdev.com/ets2sync_helper.zip

## Video Tutorial
Portuguese audio, English subtitles (CC).

https://www.youtube.com/watch?v=WKLHSnt_5H4

## How To Sync
1. In the game, create a save (“Save & Load” → “Save Game”, type a name, click “Save”).
2. Press Alt+Tab to minimize the game.
3. Open the app (or click “Reload” if it was already open).
4. If there are any messages in red:
	* “Wrong Save Format”:
		1. Exit the game. This step won't work if the game is running.
		2. In the app, click “Fix”.
		3. Confirm the messages.
		4. Open the game again.
		5. Go back to step 1.
	* “No saves found”:
		1. Click “Reload”.
		2. Make sure that the correct profile is selected.
		3. Go back to step 1.
5. If there are no messages in red, click “Sync”.
6. Wait until the message “Sync complete” appears.
7. Go back to the game. Load the save that was created on step 1 (“Save & Load” → “Load Game”).
8. In the “Freight Market”, check that the field “Offer expires in” has the same value for all jobs (and that it's about 500 hours). If it is, the sync was successful.

	If the jobs don't all have the same expiration time, that means that the sync failed. Usually when that happens it's because the person forgot to load the save after syncing, or that the save that was loaded is not the one that was synced (check the profile and the save that are selected in the app).

## Save Format
In previous versions, as well as when syncing via the website, it was necessary to have the save format set to 3 (or 2). Starting with version 3.0.0, the app can read a binary save file (i.e. a save created with `g_save_format "0"`). Therefore, it is not necessary to change the save format if it's already zero. Actually, if the save format is 2 or 3, the game may lag when creating autosaves, so keeping the save format set to zero is recommended.

## Bugs/Issues
If you find a problem in the app, report it on the link below:

https://github.com/davidsantos-br/ETS2Sync-Helper-2/issues

## Development
**Note:** This step is not necessary to sync the jobs.

If you wish to run the app from its source code and/or help with its development:

1. Clone the repo.
2. Install Ruby 2.2.x (http://rubyinstaller.org/).
3. Install the gems `qtbindings`, `parser`, and `wdm`:

	```
	gem install qtbindings parser wdm
	```
4. If you wish to build a binary, install the gem `ocra`:

	```
	gem install ocra
	```
5. Run the program with `verbose.bat` or `no_console.bat`.
6. If you added/changed language files, check if they are correct with `check_lang.bat`, passing the languages as a parameters (default: all languages). If there are problems, the script will show them, otherwise it will show the message `Language definitions OK`.
7. To generate a binary, run `build_exe.bat`.

### Gem `qtbindings` bug

A bug in the gem `qtbindings` related to encodings prevents the program from running from a binary created by `ocra` if the Windows username of the person running the program has accents or other special characters. I found out that the following changes fix the problem:

#### Gem `qtbindings`
In the file `lib/Qt4.rb`, replace lines 12-17 with the lines below:

```ruby
ruby_version = RUBY_VERSION.split('.')[0..1].join('.').encode("UTF-8")
if windows
	ENV['PATH'] = (File.join(File.dirname(__FILE__).encode("UTF-8"), '../bin') + ';' + File.join(File.dirname(__FILE__).encode("UTF-8"), "../lib/#{ruby_version}") + ';' + File.join(File.dirname(__FILE__).encode("UTF-8"), "../bin/#{ruby_version}") + ';' + ENV['PATH'].encode("UTF-8")).encode(ENV['PATH'].encoding)
end
$: << File.join(File.dirname(__FILE__).encode("UTF-8"), "../lib/#{ruby_version}").encode("filesystem")
require "#{ruby_version}/qtruby4"
```

#### Gem `qtbindings-qt` (`qtbindings` dependency):
In the file `qtlib/qtbindings-qt.rb`, replace line 8 with the one below:

```ruby
ENV['PATH'] = (File.join(File.dirname(__FILE__).encode("UTF-8"), '../qtbin') + ';' + File.join(File.dirname(__FILE__).encode("UTF-8"), '../qtbin/plugins') + ';' + ENV['PATH'].encode("UTF-8")).encode(ENV['PATH'].encoding)
```
