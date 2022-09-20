package eu.fays.sandweb.rest;

import static eu.fays.sandweb.util.SortOrder.DESC;
import static java.io.File.pathSeparator;
import static java.lang.System.lineSeparator;
import static java.text.MessageFormat.format;
import static java.util.Collections.unmodifiableSet;
import static java.util.Collections.unmodifiableSortedSet;
import static java.util.stream.Collectors.toCollection;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.Base64;
import java.util.Enumeration;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.SortedMap;
import java.util.SortedSet;
import java.util.TimeZone;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.zip.DeflaterOutputStream;
import java.util.zip.GZIPOutputStream;

import org.apache.tomcat.jakartaee.commons.io.IOUtils;
import org.apache.tomcat.util.http.fileupload.FileItem;
import org.apache.tomcat.util.http.fileupload.FileUploadException;
import org.apache.tomcat.util.http.fileupload.disk.DiskFileItemFactory;
import org.apache.tomcat.util.http.fileupload.servlet.ServletFileUpload;
import org.apache.tomcat.util.http.fileupload.servlet.ServletRequestContext;

import eu.fays.sandweb.util.ValueComparator;
import jakarta.servlet.ServletContext;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * An utility service to dump the request content.
 * @author Frederic Fays
 */
@SuppressWarnings("serial")
@WebServlet(urlPatterns = { "/Dump/*", "/Dump" })
public class Dump extends HttpServlet {

	public static final String ACCEPT_ENCODING = "Accept-Encoding";
	public static final String CACHE_CONTROL = "Cache-Control";
	public static final String CONTENT_ENCODING = "Content-Encoding";
	public static final String CONTENT_TYPE = "Content-Type";

	/**
	 * @see jakarta.servlet.http.HttpServlet#doPost(jakarta.servlet.http.HttpServletRequest, jakarta.servlet.http.HttpServletResponse)
	 */
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		HttpSession session = request.getSession(false);
		response.setHeader(CONTENT_TYPE, "text/plain");
		response.setHeader(CACHE_CONTROL, "no-cache");

		OutputStream compressedOut = null;
		if (request.getHeader(ACCEPT_ENCODING) != null) {
			Set<String> acceptedEncodings = getValuesSortedByQuality(request, ACCEPT_ENCODING);
			if (acceptedEncodings.contains("gzip")) {
				response.setHeader(CONTENT_ENCODING, "gzip");
				compressedOut = new GZIPOutputStream(response.getOutputStream());
			}
			if (compressedOut == null && acceptedEncodings.contains("deflate")) {
				response.setHeader(CONTENT_ENCODING, "deflate");
				compressedOut = new DeflaterOutputStream(response.getOutputStream());
			}
		}

		final PrintWriter writer = new PrintWriter(compressedOut != null ? compressedOut : response.getOutputStream());

		List<FileItem> multipartFormDataItems = null;
		boolean isAuthorized = true;

		{
			writer.println("REQUEST HEADERS");
			Enumeration<String> requestHeaders = request.getHeaderNames();
			while (requestHeaders.hasMoreElements()) {
				String header = requestHeaders.nextElement();
				writer.println(format("{0}: {1}", header, request.getHeader(header)));
			}
			writer.println("--------------------------------------------------------------------------------");
		}
		{
			writer.println("CGI PARAMETERS");
			Enumeration<String> requestParams = request.getParameterNames();
			while (requestParams.hasMoreElements()) {
				String param = requestParams.nextElement();
				String[] values = request.getParameterValues(param);
				for (String value : values) {
					writer.println(format("{0}: {1}", param, value));
				}
			}
			writer.println("--------------------------------------------------------------------------------");
		}
		{
			writer.println("MULTIPART/FORM-DATA PARAMETERS");
			if (ServletFileUpload.isMultipartContent(request)) {
				DiskFileItemFactory diskFileItemFactory = new DiskFileItemFactory();

				// Enforce the DeferredFileOutputStream to record on a temporary file
				diskFileItemFactory.setSizeThreshold(0);

				// Containment: record the temporary file in the servlet context temporary folder.
				File servletContextTempdir = (File) getServletContext().getAttribute("jakarta.servlet.context.tempdir");
				diskFileItemFactory.setRepository(servletContextTempdir);

				ServletFileUpload servletFileUpload = new ServletFileUpload(diskFileItemFactory);
				try {
					final ServletRequestContext servletRequestContext = new ServletRequestContext(request);
					multipartFormDataItems = servletFileUpload.parseRequest(servletRequestContext);
					for (FileItem fileItem : multipartFormDataItems) {
						if (fileItem.isFormField()) {
							writer.println(format("{0}: {1}", fileItem.getFieldName(), fileItem.getString()));
						} else {
							writer.println(format("{0}! {1}", fileItem.getFieldName(), fileItem.getName()));
						}
					}

				} catch (FileUploadException e) {
					throw new ServletException(e);
				}
			}

			writer.println("--------------------------------------------------------------------------------");
		}
		{
			writer.println("REQUEST ATTRIBUTES");
			Enumeration<String> requestAttrs = request.getAttributeNames();
			while (requestAttrs.hasMoreElements()) {
				String attribute = requestAttrs.nextElement();
				writer.println(format("{0}: {1}", attribute, request.getAttribute(attribute)));
			}
			writer.println("--------------------------------------------------------------------------------");
		}
		{
			writer.println("COOKIES");
			try {
				for (Cookie cookie : request.getCookies()) {
					writer.println(format("{0}: {1}", cookie.getName(), cookie.getValue()));
				}
			} catch (NullPointerException e) {
				// Do nothing
			}
			writer.println("--------------------------------------------------------------------------------");
		}
		if (session != null) {
			writer.println("SESSION");
			Enumeration<String> sessionAttrs = session.getAttributeNames();
			while (sessionAttrs.hasMoreElements()) {
				String attribute = sessionAttrs.nextElement();
				String value = session.getAttribute(attribute).toString();
				if ("password".equals(attribute)) {
					value = value.replaceAll(".", "*");
				}
				writer.println(format("{0}: {1}", attribute, value));
			}
			writer.println("--------------------------------------------------------------------------------");
		}
		{
			writer.println("BASIC AUTHENTICATION");
			String login = "";
			String password = "";

			String authorization = request.getHeader("authorization");
			if (authorization != null) {

				String b = new String(Base64.getDecoder().decode(authorization.split(" ")[1]));
				int c = b.indexOf(':');
				if (c >= 0) {
					login = b.substring(0, c);
					password = b.substring(c + 1);
				} else {
					login = b;
				}

				writer.println(format("authorization: {0}", authorization));
				writer.println(format("login: {0}", login));
				writer.println(format("password: {0}", password));
			}
			writer.println("--------------------------------------------------------------------------------");
		}
		{
			writer.println("REMOTE INFORMATIONS");
			writer.println(format("RemoteAddr: {0}", request.getRemoteAddr()));
			writer.println(format("RemoteHost: {0}", request.getRemoteHost()));
			writer.println(format("RemotePort: {0}", Integer.toString(request.getRemotePort())));
			writer.println(format("RemoteUser: {0}", request.getRemoteUser() == null ? "" : request.getRemoteUser()));
			writer.println("--------------------------------------------------------------------------------");
		}
		{
			writer.println("MISCALENEOUS");
			writer.println(format("Method: {0}", request.getMethod()));
			writer.println(format("Length: {0}", Integer.toString(request.getContentLength())));
			writer.println(format("Secure: {0}", request.isSecure()));
			writer.println(format("RequestURL: {0}", request.getRequestURL().toString()));
			writer.println(format("Scheme: {0}", request.getScheme()));
			writer.println(format("MetaDataVersion: {0}", request.getProtocol()));
			if (session != null) {
				writer.println(format("SessionCreationTime: {0}", new SimpleDateFormat("dd-MMM-yyyy HH:mm:ss Z").format(session.getCreationTime())));
				writer.println(format("SessionMaxInactiveInterval: {0}", Integer.toString(session.getMaxInactiveInterval())));
			}
			if (request.getQueryString() != null) {
				writer.println(format("QueryString: {0}", request.getQueryString()));
			}
			writer.println(format("ContextPath: {0}", getServletContext().getServletContextName()));
			writer.println(format("TimeZone: {0}", TimeZone.getDefault().getDisplayName()));
			if (isAuthorized) {
				writer.println(format("ServletContextPath: {0}", getServletContext().getRealPath("")));
			}
			writer.println("--------------------------------------------------------------------------------");
		}
		{
			writer.println("MULTIPART/FORM-DATA FILE");
			if (ServletFileUpload.isMultipartContent(request)) {
				for (FileItem fileItem : multipartFormDataItems) {
					if (!fileItem.isFormField()) {
						writer.println(format("---- file-name: {0} -- content-type: {1} ----", fileItem.getName(), fileItem.getContentType()));
						InputStream is = fileItem.getInputStream();
						IOUtils.copy(is, writer);
						writer.println();
					}
				}
			}
			writer.println("--------------------------------------------------------------------------------");
		}
		{
			writer.println("DATA");
			if (request.getContentLength() != -1) {
				try {
					InputStream is = request.getInputStream();
					IOUtils.copy(is, writer);
				} catch (IOException e) {
					writer.println(format("IOException: {0}", e.getMessage()));
				}
			}
			writer.println("--------------------------------------------------------------------------------");
		}
		if (isAuthorized) {
			writer.println("SERVLET CONTEXT");
			ServletContext context = this.getServletContext();
			Enumeration<String> contextAttrs = context.getAttributeNames();
			while (contextAttrs.hasMoreElements()) {
				String attribute = contextAttrs.nextElement();
				Object value = context.getAttribute(attribute);
				if (attribute.matches(".*path$") && (value instanceof String)) {
					StringBuilder buffer = new StringBuilder();
					String[] paths = ((String) value).split(pathSeparator);
					for (String path : paths) {
						buffer.append(path);
						buffer.append(lineSeparator());
					}
					value = buffer.toString();
				}
				if ("org.apache.catalina.WELCOME_FILES".equals(attribute)) {
					String[] welcomeFiles = (String[]) value;
					StringBuilder buffer = new StringBuilder();
					for (String welcomeFile : welcomeFiles) {
						buffer.append(welcomeFile);
						buffer.append(lineSeparator());
					}
					value = buffer.toString();
				}
				writer.println(format("{0}: {1}", attribute, value));
			}
			writer.println("--------------------------------------------------------------------------------");
		}
		if (isAuthorized) {
			writer.println("SYSTEM PROPERTIES");
			final SortedSet<String> systemProperties = unmodifiableSortedSet(System.getProperties().keySet().stream().map(o -> o.toString()).collect(toCollection(TreeSet::new)));
			for (String property : systemProperties) {
				String value = System.getProperty(property);

				if (property.matches(".*\\.path$") || property.matches(".*\\.dirs$")) {
					StringBuilder buffer = new StringBuilder();
					String[] paths = value.split(pathSeparator);
					for (int i = 0; i < paths.length; i++) {
						buffer.append(paths[i]);
						buffer.append(lineSeparator());
					}
					value = buffer.toString();
				}
				writer.println(format("{0}: {1}", property, value));
			}
		}

		writer.flush();
		if (compressedOut != null) {
			compressedOut.flush();
			compressedOut.close();
		}
	}

	/**
	 * @see jakarta.servlet.http.HttpServlet#doGet(jakarta.servlet.http.HttpServletRequest, jakarta.servlet.http.HttpServletResponse)
	 */
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		doPost(req, resp);
	}

	/**
	 * Returns the list of values sorted in reverse order based on their quality factor &rArr; the value with the highest quality comes first.
	 * @param request the HTTP request.
	 * @param header the HTTP request header
	 * @return the list of values.
	 */
	public static Set<String> getValuesSortedByQuality(final HttpServletRequest request, final String header) {
		//
		assert request != null;
		assert header != null;
		//

		final Map<String, Double> map = new LinkedHashMap<>();
		final String acceptHeader = request.getHeader(header);
		if (acceptHeader != null && !acceptHeader.isEmpty()) {
			final String[] list = acceptHeader.split(",");
			for (String item : list) {
				final String[] parts = item.split(";");
				final String value = parts[0].trim().toLowerCase();
				Double qualityFactor = 1d;
				if (parts.length > 1) {
					final String[] subparts = parts[1].split("=");
					if (subparts.length > 1) {
						try {
							qualityFactor = Double.parseDouble(subparts[1]);
						} catch (NumberFormatException e) {
							// Do Nothing
						}
					}
				}
				map.put(value, qualityFactor);
			}
		}

		final SortedMap<String, Double> result = new TreeMap<>(new ValueComparator<String, Double>(map, DESC));
		result.putAll(map);

		return unmodifiableSet(new LinkedHashSet<String>(result.keySet()));
	}
}
