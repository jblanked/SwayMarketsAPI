//+------------------------------------------------------------------+
//|                                                  SwayMarkets.mqh |
//|                                          Copyright 2024,JBlanked |
//|                                        https://www.jblanked.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024,JBlanked"
#property link      "https://www.jblanked.com/"
#include <api.mqh>
#include <jb-log.mqh> // logging
// SwayMarkets documentation: https://sway-technologies.gitbook.io/swaycharts-api-docs
class CSwayMarkets
  {
private:

   string            base_url;
   string            session_token;
   string            username;
   string            account_name;

   CLog              *logger;

public:

   datetime          timeout;

                     CSwayMarkets::CSwayMarkets()
     {
      base_url = "https://api.swaycharts.io/dxsca-web/";
      session_token = "";
      username = "";
      account_name = "";
      this.logger = new CLog("SwayMarketsLibrary",false);
     }

   CSwayMarkets::   ~CSwayMarkets()
     {
      if(this.logger != NULL)
        {
         delete logger;
        }

     }

   // login and set the token + initializers
   bool              login(const string username, const string password, const string account_name);

   bool              logout(); // logout of the session/token

   CJAVal            account_summary();

   CJAVal            get_users(); // useful if having trouble finding account info

   bool              ping(); // keep server alive

   string            send_order(
      string order_code, // unique number for each order
      string symbol, // currency pair
      int quantity = 1000, // almost like lotsize, 1000 = 0.01 lot
      string side = "BUY" // BUY or SELL
   ); // returns an orderID

   bool              close_position(
      string order_code, // unique name/number for each order
      string symbol,  // same symbol as the one used to open the position
      string side,  // opposite side of the position, so if you opened a buy position, you close with a sell
      string position_code  // position code of the position you want to close
   );

  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSwayMarkets::login(const string userName,const string passWord,const string accountName)
  {
   this.logger.log("Logging in to " + accountName);
   api.url = base_url + "login";

   api.loader.Clear();

   api.loader["username"] = userName;
   api.loader["domain"] = "default";
   api.loader["password"] = passWord;

   username = userName; // set the username value to be used later on
   account_name = "default:" + accountName; // set the account name value to be used later on

   if(api.POST(api.loader,10000,NULL,base_url))   // if POST request is successful
     {
      this.logger.log("Logged in.");
      session_token = api.loader["sessionToken"].ToStr(); // set the session token as token provided in the response
      timeout = TimeCurrent() + 60; // 1 minute from now
      return true; // return true
     }
   else
     {
      this.logger.print("Failed to login: " + api.result);
      return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSwayMarkets::logout(void)
  {
   this.logger.log("Logging out.");
   api.url = base_url + "logout"; // logout url

// required headers
   const string headers = "Content-Type: application/json" + "\r\n" + "Accept:" + "application/json" "\r\n" + "Authorization:" "DXAPI " + session_token;

   if(api.POST(10000,headers,base_url))
     {
      this.logger.log("Logged out successfully.");
      return true;
     }
   else
     {
      this.logger.print("Failed to log out: " + api.result);
      return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CJAVal CSwayMarkets::account_summary(void)
  {
   this.logger.log("Fetching account summary.");
   api.url = base_url + "accounts/" + account_name + "/metrics"; // account summary url

// required headers
   const string headers = "Content-Type: application/json" + "\r\n" + "Accept:" + "application/json" "\r\n" + "Authorization:" "DXAPI " + session_token;

   CJAVal metrics; // create JSON object

   api.GET(headers);  // send GET request

   metrics = api.loader["metrics"][0]; // set JSON object provided from the account metrics

   return metrics; // return the JSON object
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CJAVal CSwayMarkets::get_users(void)
  {
   this.logger.log("Fetching users.");
   api.url = base_url + "users/" + username + "@default"; // get users url

// required headers
   const string headers = "Content-Type: application/json" + "\r\n" + "Accept:" + "application/json" "\r\n" + "Authorization:" "DXAPI " + session_token;

   api.GET(headers); // send GET request

   return api.loader; // return the JSON object
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSwayMarkets::ping(void)
  {
   this.logger.log("Sending ping to server.");
   api.url = base_url + "ping"; // ping url

// required headers
   const string headers = "Content-Type: application/json" + "\r\n" + "Accept:" + "application/json" "\r\n" + "Authorization:" "DXAPI " + session_token;

   if(api.POST(10000,headers,base_url))
     {
      this.logger.log("Pinged successfully.");
      return true;
     }
   else
     {
      this.logger.log("Ping failed: " + api.result);
      return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CSwayMarkets::send_order(string order_code,string symbol,int quantity=1000,string side="BUY")
  {
   this.logger.log("Sending " + side + " on " + symbol + " with " + string(quantity) + " volume.");
   api.loader.Clear(); // erase previous saved values

   api.url = base_url + "accounts/" + account_name + "/orders"; // send order url

// required headers
   const string headers = "Content-Type: application/json" + "\r\n" + "Accept:" + "application/json" "\r\n" + "Authorization:" "DXAPI " + session_token;

   api.loader["orderCode"] = order_code; // unique number for each order
   api.loader["type"] = "MARKET"; // MARKET, LIMIT, STOP
   api.loader["instrument"] = symbol; // currency pair
   api.loader["quantity"] = quantity; // almost like lotsize, 1000 = 0.01 lot
   api.loader["positionEffect"] = "OPEN";
   api.loader["side"] = side; // BUY or SELL
   api.loader["tif"] = "GTC"; // time in force/expiration of order

   if(api.POST(api.loader,10000,headers,base_url))
     {

      const string orderid =  api.loader["orderId"].ToStr();

      if(orderid == "")
        {
         this.logger.print("Order may have sent but the returned ticket is -1: " + api.result);
         return "-1";
        }
      else
        {
         this.logger.log("Order sent successfully. Order ID: " + string(orderid));
         return orderid; // return the provided Order ID
        }
     }

   else
     {
      this.logger.log("Failed to send POST request: " + api.result);
      return "-1";
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSwayMarkets::close_position(string order_code,string symbol,string side,string position_code)
  {
   this.logger.log("Attempting to closing position " + position_code + " with order code " + order_code);

   api.loader.Clear(); // erase previous saved values

   api.url = base_url + "accounts/" + account_name + "/orders"; // close positions url

// required headers
   const string headers = "Content-Type: application/json" + "\r\n" + "Accept:" + "application/json" "\r\n" + "Authorization:" "DXAPI " + session_token;

   api.loader["orderCode"] = order_code; // unique number for each order
   api.loader["type"] = "MARKET"; // MARKET, LIMIT, STOP
   api.loader["instrument"] = symbol; // currency pair - same symbol as the initial symbol
   api.loader["positionEffect"] = "CLOSE";
   api.loader["side"] = side; // BUY or SELL - must be opposite of the initial trade
   api.loader["tif"] = "GTC"; // time in force/expiration of order
   api.loader["positionCode"] = position_code; // orderId returned when placed the initial trade

   if(api.POST(api.loader,10000,headers,base_url))
     {
      this.logger.log("Order closed successfully.");
      return true;
     }
   else
     {
      this.logger.print("Failed to close position " + position_code + " with order code " + order_code + ": " + api.result);
      return false; // otherwise return false
     }
  }
//+------------------------------------------------------------------+
