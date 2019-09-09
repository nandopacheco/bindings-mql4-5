//+------------------------------------------------------------------+
//|                                                      hitback.mq5 |
//|                                         Copyright 2017, Hitback. |
//|                                           https://www.hitback.us |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Hitback."
#property link      "https://www.hitback.us"
#property version   "1.00"
#property strict

//--- Include a class of the Standard Library
#include <Trade/Trade.mqh>
#include <Zmq/Zmq.mqh>
#include <json.mqh>

string currency = Symbol();
extern string ip_adress = "*";
extern string prefixPort = "20";

// ZMQ
Context context;
Socket socket(context,ZMQ_PUB);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   MarketBookAdd(currency);
   
 // Print("using zeromq version "+getVersion());
  if( socket.bind("tcp://"+serverAdress( currency )) ) 
  {
      Print("Problem with ZMQ bind " + "tcp://"+serverAdress( currency ));
  }else{
      Print("ZMQ bind " + "tcp://"+serverAdress( currency ) + " Connected");
  }
  
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- close the DOM
   if(!MarketBookRelease(currency))
      Print("Failed to close the DOM!");
  }
  
string serverAdress(string symbol_received)
  {
     string str = "";

      if( "BTCUSDT" == symbol_received ) {
         str=ip_adress+":"+prefixPort+"88";
         return str;
      }
      
   return(str);
  
  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
  // Print("Book event for: "+symbol);
//--- select the symbol
   if(symbol==_Symbol)
     {
      //--- array of the DOM structures
      MqlBookInfo last_bookArray[];
     
      
      //--- get the book
      if(MarketBookGet(_Symbol,last_bookArray))
        {
        
         JSONArray* jaTicks = new JSONArray();

         //--- process book data
         for(int idx=0;idx<ArraySize(last_bookArray);idx++)
           {
            MqlBookInfo curr_info=last_bookArray[idx];
             jaTicks.put(idx, Serialize(last_bookArray[idx]));
           }
         
          // ZMQ send msg
            string msg = CreateSuccessResponse("book", jaTicks);  
            ZmqMsg request(msg);
            socket.send(request);
         
        }
     }
  }

string CreateSuccessResponse(string responseName, JSONValue* responseBody)
{
   JSONObject *joResponse = new JSONObject();
   joResponse.put("ErrorCode", new JSONString("0"));
      
   if (responseBody != NULL)
   {
      joResponse.put(responseName, responseBody);   
   }
   
   string result = joResponse.toString();   
   delete joResponse;   
   return result;
}

JSONObject* Serialize(MqlBookInfo& tick)
{
    JSONObject *jo = new JSONObject();
    jo.put("type", new JSONString(tick.type));
    jo.put("price", new JSONNumber(tick.price));
    jo.put("volume", new JSONNumber(tick.volume));
    return jo;
}

void SendTickData()
{
   MqlTick last_tick;
   
   if(SymbolInfoTick(currency,last_tick))
     {

       JSONObject *jo = new JSONObject();
       jo.put("time", new JSONNumber(last_tick.time));
       jo.put("bid", new JSONNumber(last_tick.bid));
       jo.put("ask", new JSONNumber(last_tick.ask));
       jo.put("last", new JSONNumber(last_tick.last));
       jo.put("volume", new JSONNumber(last_tick.volume));
         
        // ZMQ send msg
        string msg = CreateSuccessResponse("tick", jo);  
        ZmqMsg request(msg);
        socket.send(request);
        
     }
   else Print("SymbolInfoTick() failed, error = ",GetLastError());;
}
   
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
 
   SendTickData();
      
  }