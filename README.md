# Monzo Viewer

This is my first application written in Rails, so there will probably be a few issues here and there. However it *should* be consistent in what it does.

As for what it does:

* Display all accounts and their balance

* List transactions, any round-ups are merged into their respective transaction and marked

* Display Pots and their curent balance

* Pots can have multiple targets

* Transfer any money you have, when you have a transaction valuing a certain threshold, deposited into a savings pot with the ability to set an offset

* Automatic updating (this is done hourly via the whenever gem and requires a cron capable OS)

# Requirements

The requirements to run this application are Ruby on Rails 6.0, the ability to install the gems required (done after cloning this repository).

Subsequently, Ruby on Rails requires Ruby, Node.JS and Yarn.

This has been tested with the following versions

```Ruby: 2.6.6```

```Node.JS: 14.15.4```

```Yarn: 1.22.5```

```Rails: 6.0.3```

If you wish to have the app automatically update the transactions and transfer money when a transaction meets to threshold, you also need to have to ability to run sceduled commands.
Officially this is done via the whenever gem, however you can set it up in anyway you like so long as you can run a command on schedule.
# Setup

You can check to make sure you have everything installed by running the following commands

```ruby --version```

```node --version```

```yarn --version```

```rails --version```

If you are missing anything, follow their guides on how to install

* [Ruby](https://www.ruby-lang.org/en/documentation/installation/)
* [NodeJS](https://nodejs.org/en/download/)
* [Yarn](https://classic.yarnpkg.com/en/docs/install)
* [Rails](https://guides.rubyonrails.org/getting_started.html)

Once all of the above are installed and ready to go, clone this repository or download a zip and extract to a location of your choosing.

Once in this location, open a terminal / command prompt and type

```bundle install```

This will download and install all the required gems for this application, once this has finished, run: 

```rails webpacker:install```

This will setup webpacker for your system. If it asks you to overwite anything, just hit **N**. Next, type:

```rails db:migrate```

This will setup the database. Finally, to start the server type:

```rails server```

The app will now be running and accessible on ```localhost:3000```. (While the app is in dev mode, if you wish to access this anywhere other than the local machine, add ```-b 0.0.0.0``` to the server start command)

# Getting Started

First you must create an account, nothing more than a username and password is required.

Afterwards, the first run setup will take you through setting up an OAuth Client on the monzo dev portal. 
Please be sure to follow the instructions when setting up the OAuth Client, especially the redirect URL. The name and description can be anything you like, but you **must** set the redirect URL to what the app gives you.
When authorising the app, please also ensure you open the email from the device you are setting the app up on, if you open it on another device, you will have to re-authenticate.

After the app has been authenticated, you will have to allow access via the Monzo app, then you can click the button to download all account data.
You will have 5 minutes from authorising in the app to download all the account data. If you leave it longer than this, you will have to re-authenticate.

# Transfer Money To Savings Pot

If a transaction is a debit (that is, you are receiving money), the previous transaction had a positive balance and your current balance is above the previous transactions balance, there will be an option to transfer the previous transactions balance to a savings pot. By default, this pot is set to the first pot on your account, however you can change this to be whatever pot you like on the settings page.

If you wish, you can have this automated if you set a some conditions in the settings, it will then transfer the money when it downloads the transaction data. 
If you would like this completely automated, you should have a way of running the ```rake accounts:update``` command.
Officially this is supported by using the whenever gem. Running ```whenever --update-crontab --set environment='development'``` will update your crontab to run the account update at regular intervals.
By default this is set to run every hour and will check the previous two hours worth of transactions, but can be changed in the ```config/schedule.rb``` file.

The conditions for automatically transferring money to a pot can either be based on transaction value (Is the transaction above the set value?), or by description (Does the transaction description contain the set value?). All conditions much pass in order to transfer money to a pot automatically.

# Updating Accounts

If you do not/cannot run the sceduled task, you can update the accounts and transactions from the settings page, this will update everything going back 60 days. If you have not updated the accounts for longer than this, it is recommended that you re-run the first run setup.

Please note that you cannot take advantage of the automatic pot deposits if you update using this method.

# Re-running The First Run Setup

From the settings page, you can go back to the first run setup, this will allow you to sync everything from your account. At this point you can choose to just sync whatever is missing, or start afresh. Be warned that if you choose to start afresh, it will **delete all customisations** such as account name changes, pot targets and automatic pot deposits.

# Keeping Authenticated

Due to SCA (Strong Customer Authentication) the app will remain authenticated for 90 days from the date it is authorised. You can extend this authorisation at any time by going into the app, tapping on your icon, going to settings, go into "Privacy & Security" and "Manage Apps". At the bottom of the screen, you can "Refresh permissions" which will refresh the authentication back to 90 days. If this expires, you will have to re-run the first setup, which you can do from the settings screen.