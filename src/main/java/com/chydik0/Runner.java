package com.chydik0;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Runner {
    public static final Logger LOGGER = LoggerFactory.getLogger(Runner.class);

    public static void main(String[] args) {
        PhoneCompanyApp app = new PhoneCompanyApp();
        app.run();
    }
}