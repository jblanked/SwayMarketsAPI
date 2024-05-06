//+------------------------------------------------------------------+
//|                                                  SwayMarkets.mqh |
//|                                          Copyright 2024,JBlanked |
//|                                        https://www.jblanked.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024,JBlanked"
#property link      "https://www.jblanked.com/"
#include <api.mqh>
// SwayMarkets documentation: https://sway-technologies.gitbook.io/swaycharts-api-docs
class CSwayMarkets
{
   private:
   
      string base_url;
      string session_token;
      string username;
      string account_name;
      
   public:
   
      CSwayMarkets::CSwayMarkets()
      {
      base_url = "https://api.swaycharts.io/dxsca-web/";
      session_token = "";
      username = "";
      account_name = "";
      }
      
      // login and set the token + initializers
      bool login(const string username, const string password, const string account_name);
      
      bool logout(); // logout of the session/token
      
      CJAVal account_summary();
      
      CJAVal get_users(); // useful if having trouble finding account info
      
      bool ping(); // keep server alive
      
      string send_order(
         string order_code, // unique number for each order
         string symbol, // currency pair
         int quantity = 1000, // almost like lotsize, 1000 = 0.01 lot
         string side = "BUY" // BUY or SELL
      ); // returns an orderID
      
      bool close_position(
         string order_code, // unique name/number for each order
         string symbol,  // same symbol as the one used to open the position
         string side,  // opposite side of the position, so if you opened a buy position, you close with a sell
         string position_code  // position code of the position you want to close
      );
   
};

bool CSwayMarkets::login(const string userName,const string passWord,const string accountName)
{
   api.url = base_url + "login";
   
   api.loader["username"] = userName;
   api.loader["domain"] = "default";
   api.loader["password"] = passWord; //

   username = userName; // set the username value to be used later on
   account_name = "default:" + accountName; // set the account name value to be used later on
   
   if(api.POST(api.loader,10000,NULL)) { // if POST request is successful
    session_token = api.loader["sessionToken"].ToStr(); // set the session token as token provided in the response
    return true; // return true
   }
   else return false; // otherwise return false
}

bool CSwayMarkets::logout(void)
{
   api.url = base_url + "logout"; // logout url
   
   // required headers
   const string headers = "Content-Type: application/json" + "\r\n" + "Accept:" + "application/json" "\r\n" + "Authorization:" "DXAPI " + session_token;

   if(api.POST(10000,headers)) return true; // if successful return true
   else return false; // otherwise return false
}

CJAVal CSwayMarkets::account_summary(void)
{
   api.url = base_url + "accounts/" + account_name + "/metrics"; // account summary url
   
   // required headers
   const string headers = "Content-Type: application/json" + "\r\n" + "Accept:" + "application/json" "\r\n" + "Authorization:" "DXAPI " + session_token;
   
   CJAVal metrics; // create JSON object 
   
   api.GET(headers);  // send GET request
   
   metrics = api.loader["metrics"][0]; // set JSON object provided from the account metrics
   
   return metrics; // return the JSON object
}

CJAVal CSwayMarkets::get_users(void)
{
   api.url = base_url + "users/" + username + "@default"; // get users url
   
   // required headers
   const string headers = "Content-Type: application/json" + "\r\n" + "Accept:" + "application/json" "\r\n" + "Authorization:" "DXAPI " + session_token;
   
   api.GET(headers); // send GET request
   
   return api.loader; // return the JSON object
}

bool CSwayMarkets::ping(void)
{
   api.url = base_url + "ping"; // ping url
   
   // required headers
   const string headers = "Content-Type: application/json" + "\r\n" + "Accept:" + "application/json" "\r\n" + "Authorization:" "DXAPI " + session_token;

   if(api.POST(10000,headers)) return true; // if successful return true
   else return false; // otherwise return false
}

string CSwayMarkets::send_order(string order_code,string symbol,int quantity=1000,string side="BUY")
{
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
             
   if(api.POST(api.loader,10000,NULL)) return api.loader["orderID"].ToStr(); // return the provided Order ID
   else return "-1"; // otherwise return -1/Error
}

bool CSwayMarkets::close_position(string order_code,string symbol,string side,string position_code)
{
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
             
   if(api.POST(api.loader,10000,NULL)) return true; // return true is successful
   else return false; // otherwise return false
}