# ETS2Sync Helper
[VERSÃO EM PORTUGUÊS](README.md)

This app synchronizes the job list on Euro Truck Simulator 2, in order to make it easier to organize a convoy on Multiplayer.

## Download
http://files.dsantosdev.com/ets2sync_helper.zip

## How To Sync
1. In the game, create a save (“Save & Load” → “Save Game”, type a name, click “Save”).
2. Press Alt+Tab to minimize the game.
3. Open the app (or click “Atualizar” if it was already open).
4. If there are any messages in red:
	* “Formato do Save incorreto”:
		1. Exit the game. This step won't work if the game is running.
		2. In the app, click “Corrigir”.
		3. Confirm the messages.
		4. Open the game again.
		5. Go back to step 1.
	* “Nenhum save encontrado”/“*x* saves, nenhum é compatível” (*x* being any number):
		1. Click “Atualizar”.
		2. Make sure that the correct profile is selected.
		3. Go back to step 1.
5. If there are no messages in red, click “Sincronizar”.
6. Wait until the message “Sincronização concluída” appears.
7. Go back to the game. Load the save that was created on step 1 (“Save & Load” → “Load Game”).
8. In the “Freight Market”, check that the field “Offer expires in” has the same value for all jobs (and that it's about 500 hours). If it is, the sync was successful.

	If the jobs don't all have the same expiration time, that means that the sync failed. Usually when that happens it's because the person forgot to load the save after syncing, or that the save that was loaded is not the one that was synced (check the profile and the save that are selected in the app).

## Bugs/Issues
If you find a problem in the app, report it on the link below:

https://github.com/davidsantos-br/ets2sync_helper/issues

## Development
**Note:** This step is not necessary to sync the jobs.

If you wish to run the app from its source code and/or help with its development:
1. Clone the repo.
2. Install Ruby 2.2.x (http://rubyinstaller.org/).
3. Install the gem `qtbindings`:
	```
	gem install qtbindings
	```
4. If you wish to build a binary, install the gem `ocra`:
	```
	gem install ocra
	```
5. Run `verbose.bat` or `no_console.bat` to execute the app.
6. To generate a binary, run `build_exe.bat`.

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
In the file `qtlib/qtbindings-qt.rb`, replace line 8 for the one below:
```ruby
ENV['PATH'] = (File.join(File.dirname(__FILE__).encode("UTF-8"), '../qtbin') + ';' + File.join(File.dirname(__FILE__).encode("UTF-8"), '../qtbin/plugins') + ';' + ENV['PATH'].encode("UTF-8")).encode(ENV['PATH'].encoding)
```
