//
//  Copyright (C) 2020 Danny Havenith
//
//  Distributed under the Boost Software License, Version 1.0. (See
//  accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt)
//
#include "WiFiConfiguration.hpp"
#include <PubSubClient.h>
#include <ESP8266WiFi.h>
#include <Arduino.h>
#include <ArduinoOTA.h>

namespace
{
    IPAddress ip{ 192, 168, 4, 1};
    IPAddress subnet{ 255, 255, 255, 240};

    WiFiClient espClient;
    PubSubClient mqttClient(espClient);

    using Pin = decltype( D1);
    struct Button
    {
        const Pin pin;
        const char * const mqttValue;
        bool lastPosition;
    };

    Button buttons[] = {
            {D2, "1", true},
            {D5, "2", true},
            {D6, "3", true},
            {D7, "4", true},
            {D3, "5", true}
    };

    bool setupAccessPoint()
    {

        WiFi.disconnect();
        WiFi.softAPConfig( ip, ip, subnet);
        WiFi.mode(WIFI_AP);

        auto result =  WiFi.softAP( myName, myPassword);

        return result;
    }

    void connectToAccessPoint()
    {
        // Connect WiFi
        WiFi.hostname( myName);
        WiFi.begin( networkSID, networkPassword);
    }

    /**
     * Wait timeOutMs milliseconds for the connection to the access point to come up.
     *
     * return true if we have a connection, false if no connection was
     * established before timeout.
     *
     * This function will also flash the builtin LED while waiting for the
     * connection to come up.
     */
    bool waitForConnectedToAccessPoint( uint16_t timeOutMs)
    {
        const auto starttime = millis();
        auto status = WiFi.status();
        while ( status != WL_CONNECTED and millis() - starttime < timeOutMs )
        {
            delay( 500);
            status = WiFi.status();
            digitalWrite( LED_BUILTIN, not digitalRead( LED_BUILTIN));
        }

        // the LED is low-active.
        digitalWrite( LED_BUILTIN, status != WL_CONNECTED);
        return status == WL_CONNECTED;
    }

    /**
     * First try to connect to a configured access point and if we're not connected within a timeout period
     * set up an access point for ourselves.
     */
    void setupNetwork()
    {
        connectToAccessPoint();

        if (not waitForConnectedToAccessPoint( 30000))
        {
            setupAccessPoint();
        }
    }

    void setupOTA()
    {
        ArduinoOTA.setHostname( myName);
        ArduinoOTA.begin();
    }

    void reconnectMqtt()
    {

        if (WiFi.status() != WL_CONNECTED)
        {
            connectToAccessPoint();
        }

        // Loop until we're reconnected
        // Create a random client ID
        mqttClient.setServer( mqttServer, mqttPort);
        String clientId = "ESP8266Client-";
        clientId += String(random(0xffff), HEX);
        static const String connectedTopic = String("Telegraph/connected");
        while ( not mqttClient.connected())
        {
            if (mqttClient.connect(clientId.c_str(), nullptr, nullptr, connectedTopic.c_str() , 0, false, "0"))
            {
                mqttClient.publish( connectedTopic.c_str(), "1");
            }
            else
            {
                digitalWrite( LED_BUILTIN, not digitalRead( LED_BUILTIN));
                delay(5000);
            }
        }
    }

    void signalValue( const char *value)
    {
        static const auto topic = "Telegraph/value";
        while (not mqttClient.publish( topic, value))
        {
            reconnectMqtt();
            delay( 500);
            digitalWrite( LED_BUILTIN, not digitalRead( LED_BUILTIN));
        }
        digitalWrite( LED_BUILTIN, HIGH);
    }

    void handleButton( Button &button)
    {
        bool position = digitalRead( button.pin);
        if ( position != button.lastPosition)
        {
            button.lastPosition = position;
            if (not position)
            {
                signalValue( button.mqttValue);
            }
        }
    }
}

void setup()
{
    for ( const auto &button: buttons)
    {
        pinMode( button.pin,  INPUT_PULLUP);
    }

    setupNetwork();
    setupOTA();
    reconnectMqtt();
}

void loop()
{
    for (auto &button : buttons)
    {
        handleButton( button);
    }
    mqttClient.loop();
    ArduinoOTA.handle();
}
