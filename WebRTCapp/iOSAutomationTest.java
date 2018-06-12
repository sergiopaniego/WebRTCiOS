package com.sergiopaniegoblanco.webrtcexampleapp;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.remote.DesiredCapabilities;
import org.openqa.selenium.remote.RemoteWebDriver;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.List;
import java.util.concurrent.TimeUnit;

import static junit.framework.Assert.assertTrue;

public class iOSAutomationTest {

    WebDriver driver;

    @Before
    public void setUp() throws MalformedURLException {
        DesiredCapabilities caps = new DesiredCapabilities();
        caps.setCapability("fullReset", true);
        caps.setCapability("app", "/Users/sergiopaniegoblanco/Library/Developer/Xcode/DerivedData/WebRTCapp-agcpguzpanyknefswbrgjpnavnpx/Build/Products/Debug-iphonesimulator/WebRTCapp.app");
        caps.setCapability("version", "11.3");
        caps.setCapability("automationName", "XCUITest");
        caps.setCapability("platform", "iOS");
        caps.setCapability("deviceName", "iPad Air 2");
        caps.setCapability("platformName", "iOS");

        driver = new RemoteWebDriver(new URL("http://127.0.0.1:4723/wd/hub"), caps);
    }

    @Test
    public void testStartSession() throws InterruptedException {
        // Accept the permission
        driver.findElement(By.xpath("//XCUIElementTypeButton[@name=\"OK\"]")).click();
        Thread.sleep(4*1000);
        driver.findElement(By.xpath("//XCUIElementTypeButton[@name=\"Start\"]")).click();
        Thread.sleep(4*1000);
        driver.findElement(By.xpath("//XCUIElementTypeOther[@name=\"RemoteView1\"]")).isDisplayed();

        driver.manage().timeouts().implicitlyWait(30,TimeUnit.SECONDS);
    }

    @After
    public void End() {
        driver.quit();
    }
}
