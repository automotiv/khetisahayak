# Activity Diagram

## User Registration

```plantuml
@startuml
start
:User opens the app;
:User navigates to the registration screen;
:User enters registration details;
:User clicks the register button;
if (details are valid?) then (yes)
  :App sends registration request to the server;
  :Server creates a new user account;
  :Server sends a success response to the app;
  :App shows a success message to the user;
  :User is logged in;
else (no)
  :App shows an error message to the user;
endif
stop
@enduml
```

## Crop Health Diagnostics

```plantuml
@startuml
start
:Farmer opens the app;
:Farmer navigates to the crop health diagnostics screen;
:Farmer uploads a crop image;
:App sends the image to the server;
:Server sends the image to the AI service;
:AI service analyzes the image;
:AI service returns the diagnosis to the server;
:Server sends the diagnosis to the app;
:App displays the diagnosis and recommendations to the farmer;
stop
@enduml
