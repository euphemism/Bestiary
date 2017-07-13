# Bestiary
The Binding of Isaac: Bestiary Mod


## How to set up the dev environment 

__Do not code directly in main.lua !!!__

First install node.js npm : https://nodejs.org/en/

Startup the node console

Install gulp globally:

```
npm install -g gulp
```

Set your working directory to the project's then install dependancies

```
npm install
```

Now before coding just do :

```
gulp watch
```

Now when you need to put code that will be accessible from anywhere put it in globals.lua. 
For any new enemy or collectible, create a lua file in the respective folder under src/ , __Avoid top level local variables in those files as they may be overriden by other files (other than the mod object: see pitbat.lua for example) __ 

And that's it, happy coding!

