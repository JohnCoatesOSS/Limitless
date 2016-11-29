### Backporting Style Guide
This is a catalog of what Cydia does differently from Limitless so that we can transfer our code back to Cydia.

### Loops
Use the defined iteration patterns.

**Preferred:**
````
_forever {
  // code
  if (condition)
    break;
}
````

**Not Preferred:**
````
while(1) {
  // code
  if (condition)
    break;
}
````

### Variable Initialization
Use constructor syntax.

**Preferred:**
````
int64_t usermem(0);
````

**Not Preferred:**
````
int64_t usermem = 0;
````


### Temporary Variables
When involving temporary variables, put them in their own scope to avoid polluting a function's scope.

**Preferred:**
````
SCNetworkReachabilityFlags flags; {
       SCNetworkReachabilityRef reachability(SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, name));
       SCNetworkReachabilityGetFlags(reachability, &flags);
       CFRelease(reachability);
   }
````

**Not Preferred:**
````
SCNetworkReachabilityFlags flags;
SCNetworkReachabilityRef reachability(SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, name));
SCNetworkReachabilityGetFlags(reachability, &flags);
CFRelease(reachability);

````
