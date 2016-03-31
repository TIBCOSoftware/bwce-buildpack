import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.net.URL;
import java.net.URLConnection;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import javax.xml.bind.DatatypeConverter;

import org.codehaus.jettison.json.JSONArray;
import org.codehaus.jettison.json.JSONException;
import org.codehaus.jettison.json.JSONObject;

/*
 * Copyright (c) 2016, TIBCO Software Inc. All rights reserved.
 * You may not use this file except in compliance with the license 
 * terms contained in the TIBCO License.md file provided with this file.
 *
 */

/**
 * @author <a href="mailto:vnalawad@tibco.com">Vijay Nalawade</a>
 *
 * @since 1.0.0
 */
public class ProfileTokenResolver {

    static String TOKEN_DELIMITER = "#";
    static String pattern         = "\\" + TOKEN_DELIMITER + "([^" + TOKEN_DELIMITER + "]+)\\" + TOKEN_DELIMITER;

    public static void main(String[] args) throws Throwable {

        String disableSsl = System.getenv("DISABLE_SSL_VERIFICATION");
        if (Boolean.parseBoolean(disableSsl)) {
            disable_ssl_verification();
        }

        Map<String, String> tokenMap = new HashMap<String, String>();
        collectEnvVariables(tokenMap);
        collectPropertiesfromConfigServer(tokenMap);
        collectServiceConfigurations(tokenMap);
        resolveTokens(tokenMap);
    }

    /**
     * This method connects to ZUUL/Spring Cloud server and fetches properties
     * based on URL specified in the service configuration. This code assumes
     * ZUUL/Spring Cloud server configuration is attached to the application as
     * a Service with following configuration.<br>
     * <b>ZUUL:</b><br>
     * {<br>
     * &#160;&#160; "credentials": { <br>
     * &#160;&#160;&#160;&#160;&#160;&#160;&#160;"uri":
     * "http://{ZUUL-SERVER-IP}:{PORT}/zuul" <br>
     * &#160;&#160;&#160;&#160;&#160;}, <br>
     * &#160;&#160;"label":"user-provided",<br>
     * &#160;&#160;"name": "zuul-config-server", <br>
     * &#160;&#160;"syslog_drain_url": "", <br>
     * &#160;&#160;"tags": [] <br>
     * }<br>
     * 
     * <b>Spring Cloud:</b><br>
     * {<br>
     * &#160;&#160; "credentials": { <br>
     * &#160;&#160;&#160;&#160;&#160;&#160;&#160;"uri":
     * "http://{SPRING-CLOUD-SERVER-IP}:{PORT}" <br>
     * &#160;&#160;&#160;&#160;&#160;}, <br>
     * &#160;&#160;"label":"user-provided",<br>
     * &#160;&#160;"name": "spring-cloud-config", <br>
     * &#160;&#160;"syslog_drain_url": "", <br>
     * &#160;&#160;"tags": [] <br>
     * }<br>
     * 
     * @param tokenMap
     * @throws Exception
     */
    @SuppressWarnings({ "unchecked", "rawtypes" })
    private static void collectPropertiesfromConfigServer(Map<String, String> tokenMap) throws Exception {
        // TODO Auto-generated method stub
        String vcap_services = System.getenv("VCAP_SERVICES");
        if (vcap_services == null || vcap_services.isEmpty()) {
            return;
        }
        JSONObject vcapObject = new JSONObject(vcap_services);
        Iterator<String> serviceItr = vcapObject.keys();
        while (serviceItr.hasNext()) {
            String servicekey = serviceItr.next();
            JSONArray services = vcapObject.getJSONArray(servicekey);
            for (int j = 0; j < services.length(); j++) {
                JSONObject serviceConfig = services.getJSONObject(j);
                if (isZuulConfigurationService(serviceConfig)) {
                    // This is ZUUL Service configuration
                    String propUrl = serviceConfig.getJSONObject("credentials").has("url") ? serviceConfig.getJSONObject("credentials")
                            .getString("url") : null;
                    if (propUrl == null) {
                        propUrl = serviceConfig.getJSONObject("credentials").has("uri") ? serviceConfig.getJSONObject("credentials")
                                .getString("uri") : null;
                    }

                    if (propUrl == null) {
                        throw new Exception("ZUUL service configuration must specify uri.");
                    }

                    String url = constructZUULAppProfileURI(propUrl);
                    System.out.println("Found ZUUL Configuration Service......");
                    System.out.println("Loading properties from [" + url + "]");
                    try {
                        URL zuulURL = new URL(url);
                        URLConnection connection = zuulURL.openConnection();
                        connection.setReadTimeout(30000);
                        connection.setConnectTimeout(30000);

                        JSONObject credentialsObject = serviceConfig.getJSONObject("credentials");
                        if (credentialsObject.has("access_token_uri")) {
                            // Protected Resource
                            // Get Authorization
                            connection.setRequestProperty("Authorization", getAuthorization(credentialsObject));
                        } else if (url.contains("@")) {
                            // Basic Auth
                            connection.setRequestProperty("Authorization", getBasicAuthentication(url));
                        }

                        Properties zuulProperties = new Properties();
                        BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream(), "UTF-8"));
                        zuulProperties.load(in);
                        in.close();
                        Enumeration enuKeys = zuulProperties.keys();
                        while (enuKeys.hasMoreElements()) {
                            String key = (String) enuKeys.nextElement();
                            String value = zuulProperties.getProperty(key);
                            tokenMap.put(key, value);
                        }
                        return;
                    } catch (Throwable t) {
                        throw new Exception("Unable to retrieve properties from ZUUL config service using URL [" + url + "].", t);
                    }
                }

                if (isSpringCloudConfigurationService(serviceConfig)) {
                    // This is Spring Cloud config Service
                    String propUrl = serviceConfig.getJSONObject("credentials").has("url") ? serviceConfig.getJSONObject("credentials")
                            .getString("url") : null;
                    if (propUrl == null) {
                        propUrl = serviceConfig.getJSONObject("credentials").has("uri") ? serviceConfig.getJSONObject("credentials")
                                .getString("uri") : null;
                    }
                    if (propUrl == null) {
                        throw new Exception("Spring cloud config service must specify uri.");
                    }
                    String url = constructSpringCloudConfigURI(propUrl);

                    System.out.println("Loading properties from [" + url + "]");
                    try {
                        URL springURL = new URL(url);
                        URLConnection connection = springURL.openConnection();
                        connection.setReadTimeout(30000);
                        connection.setConnectTimeout(30000);
                        JSONObject credentialsObject = serviceConfig.getJSONObject("credentials");
                        if (credentialsObject.has("access_token_uri")) {
                            // OAuth 2.0
                            connection.setRequestProperty("Authorization", getAuthorization(credentialsObject));
                        } else if (url.contains("@")) {
                            // Basic Auth
                            connection.setRequestProperty("Authorization", getBasicAuthentication(url));
                        }
                        StringBuilder result = new StringBuilder();
                        BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream(), "UTF-8"));
                        try {
                            String line;
                            while ((line = in.readLine()) != null) {
                                result.append(line);
                            }
                        } finally {
                            in.close();
                        }
                        if (connection.getContentType().contains("application/json")) {
                            // JSON
                            JSONObject springConfig = new JSONObject(result.toString());
                            if (springConfig.has("propertySources")) {
                                JSONArray propertySources = springConfig.getJSONArray("propertySources");
                                for (int i = 0; i < propertySources.length(); i++) {
                                    JSONObject source = propertySources.getJSONObject(i).getJSONObject("source");
                                    JSONArray propertyNames = source.names();
                                    for (int k = 0; k < propertyNames.length(); k++) {
                                        String keyName = propertyNames.getString(k);
                                        tokenMap.put(keyName, source.getString(keyName));
                                    }
                                }
                            }
                        }
                        return;
                    } catch (Throwable t) {
                        throw new Exception("Unable to retrieve properties from Spring-cloud Config service using URL [" + url + "].", t);
                    }
                }
            }
        }
    }

    private static String getAuthorization(JSONObject credentials) throws Throwable {
        // For OAUTH 2.0
        String client_id = credentials.getString("client_id");
        String client_secret = credentials.getString("client_secret");
        String accessTokenUri = credentials.getString("access_token_uri");

        String authString = client_id + ":" + client_secret;
        String authEncodedString = DatatypeConverter.printBase64Binary(authString.getBytes());
        String body = "grant_type=client_credentials";

        URL accessTokenUrl = new URL(accessTokenUri);
        URLConnection urlConnection = accessTokenUrl.openConnection();
        urlConnection.setRequestProperty("Authorization", "Basic " + authEncodedString);
        urlConnection.setDoOutput(true);
        OutputStream output = urlConnection.getOutputStream();
        output.write(body.getBytes());
        output.close();

        StringBuilder result = new StringBuilder();
        BufferedReader in = new BufferedReader(new InputStreamReader(urlConnection.getInputStream(), "UTF-8"));
        try {
            String line;
            while ((line = in.readLine()) != null) {
                result.append(line);
            }
        } finally {
            in.close();
        }

        JSONObject accessTokenConfig = new JSONObject(result.toString());
        String accessToken = accessTokenConfig.getString("access_token");
        String tokenType = accessTokenConfig.getString("token_type");
        return tokenType + " " + accessToken;
    }

    private static String getBasicAuthentication(String serverUri) throws Throwable {
        return "Basic " + DatatypeConverter.printBase64Binary(serverUri.split("@")[0].split("://")[1].getBytes());
    }

    private static boolean isSpringCloudConfigurationService(JSONObject serviceConfig) {
        boolean result = false;
        try {
            if (serviceConfig.has("tags")) {
                // Managed Service
                List<String> list = new ArrayList<String>();
                JSONArray tagsArray = serviceConfig.getJSONArray("tags");
                if (tagsArray != null && tagsArray.length() > 0) {
                    for (int k = 0; k < tagsArray.length(); k++) {
                        String tagName = tagsArray.getString(k);
                        list.add(tagName);
                    }
                }
                result = list.contains("spring-cloud") && list.contains("configuration");
            }

            if (Boolean.FALSE == result) {
                // CUPS
                result = serviceConfig.getString("name").toLowerCase().contains("spring-cloud-config");
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return result;
    }

    private static boolean isZuulConfigurationService(JSONObject serviceConfig) {
        boolean result = false;
        try {
            if (serviceConfig.has("tags")) {
                // Managed Service
                List<String> list = new ArrayList<String>();
                JSONArray tagsArray = serviceConfig.getJSONArray("tags");
                if (tagsArray != null && tagsArray.length() > 0) {
                    for (int k = 0; k < tagsArray.length(); k++) {
                        String tagName = tagsArray.getString(k);
                        list.add(tagName);
                    }
                }
                result = list.contains("zuul") && list.contains("configuration");
            }

            if (Boolean.FALSE == result) {
                // CUPS
                result = serviceConfig.getString("name").toLowerCase().contains("zuul-config");
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return result;
    }

    /**
     * 
     * @param propUrl
     *            - Base URL
     * @return 
     *         http://{ZUUL-SERVER-IP}:{PORT}/zuul/settings/{PROFILE-NAME}/{APP-NAME
     *         }.properties
     * @throws Exception
     */
    private static String constructZUULAppProfileURI(String propUrl) throws Exception {
        StringBuffer sb = new StringBuffer();
        sb.append(propUrl);
        if (!propUrl.endsWith("/")) {
            sb.append("/");
        }
        sb.append("settings/");
        String vcap_application = System.getenv("VCAP_APPLICATION");
        JSONObject vcapObject = new JSONObject(vcap_application);
        String profileName = System.getenv("APP_CONFIG_PROFILE");
        if (profileName == null) {
            profileName = "default";
        }
        String appName = vcapObject.getString("application_name");
        sb.append(profileName).append("/").append(appName).append(".properties");
        return sb.toString();
    }

    /**
     * @param propUrl
     *            - Base URL
     * @return http://{SPRING-CLOUD-SERVER-IP}:{PORT}/{APP-NAME}/{PROFILE-NAME}
     * @throws Exception
     */
    private static String constructSpringCloudConfigURI(String propUrl) throws Exception {
        StringBuffer sb = new StringBuffer();
        sb.append(propUrl);
        if (!propUrl.endsWith("/")) {
            sb.append("/");
        }
        String vcap_application = System.getenv("VCAP_APPLICATION");
        JSONObject vcapObject = new JSONObject(vcap_application);
        String profileName = System.getenv("APP_CONFIG_PROFILE");
        if (profileName == null) {
            profileName = "default";
        }
        String appName = vcapObject.getString("application_name");
        sb.append(appName).append("/").append(profileName);
        return sb.toString();
    }

    /**
     * This method collects value of ENV variables
     * 
     * @param valueMap
     */
    private static void collectEnvVariables(Map<String, String> valueMap) {
        Iterator<String> sysPropsItr = System.getenv().keySet().iterator();
        while (sysPropsItr.hasNext()) {
            String varName = sysPropsItr.next();
            valueMap.put(varName, System.getenv().get(varName));
        }
    }

    /**
     * This method collects PCF service configuration from VCAP_SERVICES env
     * variable
     * 
     * @param valueMap
     */
    @SuppressWarnings("unchecked")
    private static void collectServiceConfigurations(Map<String, String> valueMap) throws Exception {
        String vcap_services = System.getenv("VCAP_SERVICES");

        if (vcap_services == null || vcap_services.isEmpty()) {
            return;
        }

        try {
            JSONObject vcapObject = new JSONObject(vcap_services);
            Iterator<String> serviceItr = vcapObject.keys();
            while (serviceItr.hasNext()) {
                String servicekey = serviceItr.next();
                JSONArray services = vcapObject.getJSONArray(servicekey);
                for (int j = 0; j < services.length(); j++) {
                    JSONObject serviceConfig = services.getJSONObject(j);
                    Iterator<String> serviceConfigItr = serviceConfig.keys();
                    while (serviceConfigItr.hasNext()) {
                        String serviceConfigkey = serviceConfigItr.next();
                        if ("credentials".equals(serviceConfigkey)) {
                            JSONObject credentialConfig = serviceConfig.getJSONObject("credentials");
                            if (credentialConfig != null) {
                                Iterator<String> itr = credentialConfig.keys();
                                while (itr.hasNext()) {
                                    StringBuffer sb = new StringBuffer();
                                    sb.append(serviceConfig.getString("name")).append(".");
                                    sb.append("credentials.");
                                    String key = itr.next();
                                    sb.append(key);
                                    String value = credentialConfig.getString(key);
                                    if (isDBUrl(value)) {
                                        //Format DB URL
                                        String userName = credentialConfig.has("username") ? credentialConfig.getString("username")
                                                : (credentialConfig.has("user") ? credentialConfig.getString("user") : null);
                                        if (value.contains("postgres:")) {
                                            value = value.replace("postgres:", "postgresql:");
                                        }
                                        
                                        if (userName != null) {
                                            // BW does not support
                                            // username/password in the DB
                                            // URL
                                            // Remove username:password@
                                            value = value.replaceAll(userName + ":" + credentialConfig.getString("password") + "@", "");

                                            // Remove ?*
                                            if (value.contains("?")) {
                                                value = value.substring(0, value.indexOf("?"));
                                            }
                                        }

                                        // BW expects JDBC URL
                                        if (!value.startsWith("jdbc:")) {
                                            value = "jdbc:" + value;
                                        }
                                    }
                                    valueMap.put(sb.toString(), value);
                                }
                            }
                        } else {
                            StringBuffer sb = new StringBuffer();
                            sb.append(serviceConfig.getString("name")).append(".").append(serviceConfigkey);
                            valueMap.put(sb.toString(), serviceConfig.getString(serviceConfigkey));
                        }

                    }
                }
            }

        } catch (JSONException e) {
            throw new Exception("Unable to resolve Service configuration from [VCAP_SERVICES] ENV variable.", e);
        }
    }

    private static boolean isDBUrl(String value) {
        return value.startsWith("jdbc:") || value.startsWith("postgres:") || value.startsWith("postgresql:") || value.startsWith("hsqldb:") || value.startsWith("mysql:")
                || value.startsWith("oracle:") || value.startsWith("sqlserver:") || value.startsWith("db2:");
    }

    private static void resolveTokens(Map<String, String> tokenMap) throws Exception {

        String appDir = System.getenv("APPDIR");
        Path source = Paths.get(appDir, "tmp", "pcf.substvar");

        File originalFile = source.toFile();
        // Construct the new file that will later be renamed to the original
        // filename.
        Path target = Paths.get(appDir, "tmp", "pcf_updated.substvar");
        File tempFile = target.toFile();

        try (PrintWriter writer = new PrintWriter(tempFile, StandardCharsets.UTF_8.toString());
                BufferedReader br = new BufferedReader(new FileReader(originalFile))) {

            String line;
            while ((line = br.readLine()) != null) {
                while (line.contains(TOKEN_DELIMITER)) {
                    // Ensure that jdbc prefix is not configured in
                    // ApplicationProperty
                    if (line.contains("jdbc:")) {
                        line.replaceAll("jdbc:", "");
                    }
                    String oldLine = line;
                    Pattern p = Pattern.compile(pattern);
                    Matcher m = p.matcher(line);
                    StringBuffer sb = new StringBuffer();
                    while (m.find()) {
                        String var = m.group(1);
                        String val = tokenMap.containsKey(var)?tokenMap.get(var):tokenMap.get(var.toLowerCase());
                        if (val == null) {
                            String errMessage = "Value not found for Token [" + var + "].";
                            System.err.println(errMessage);
                            throw new Exception(errMessage);
                        }
                        m.appendReplacement(sb, "");
                        sb.append(val);
                    }
                    m.appendTail(sb);
                    line = sb.toString();

                    if (line.equals(oldLine)) {
                        break;
                    }
                }

                // Replace lookupValue tag with value tag
                if (line.contains("lookupValue")) {
                    line = line.replace("lookupValue", "value");
                }

                writer.println(line);
            }
            writer.flush();
        }

        // Delete the original file
        if (!originalFile.delete()) {
            System.out.println("Could not delete file");
            return;
        }

        // Rename the new file to the filename the original file had.
        if (!tempFile.renameTo(originalFile)) {
            System.out.println("Could not rename file");
        }

    }

    private static void disable_ssl_verification() {

        try {

            // Create a trust manager that does not validate certificate chains
            TrustManager[] trustAllCerts = new TrustManager[] { new X509TrustManager() {
                @Override
                public java.security.cert.X509Certificate[] getAcceptedIssuers() {
                    return null;
                }

                @Override
                public void checkClientTrusted(X509Certificate[] certs, String authType) {
                }

                @Override
                public void checkServerTrusted(X509Certificate[] certs, String authType) {
                }
            } };

            // Install the all-trusting trust manager
            SSLContext sc;
            sc = SSLContext.getInstance("SSL");
            sc.init(null, trustAllCerts, new java.security.SecureRandom());
            HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());

            // Create all-trusting host name verifier
            HostnameVerifier allHostsValid = new HostnameVerifier() {
                @Override
                public boolean verify(String hostname, SSLSession session) {
                    return true;
                }
            };

            // Install the all-trusting host verifier
            HttpsURLConnection.setDefaultHostnameVerifier(allHostsValid);

        } catch (NoSuchAlgorithmException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        } catch (KeyManagementException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }
}
