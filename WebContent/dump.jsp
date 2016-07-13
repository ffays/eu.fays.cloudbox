<%@page import="java.io.File"%>
<%@page import="java.io.FileOutputStream"%>
<%@page import="java.io.IOException"%>
<%@page import="java.io.PrintWriter"%>
<%@page import="java.nio.ByteBuffer"%>
<%@page import="java.nio.channels.Channels"%>
<%@page import="java.nio.channels.FileChannel"%>
<%@page import="java.nio.channels.ReadableByteChannel"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.Base64"%>
<%@page import="java.util.Enumeration"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Set"%>
<%@page import="java.util.TimeZone"%>
<%@page import="java.util.TreeSet"%>
<%@page import="javax.servlet.ServletContext"%>
<%@page import="javax.servlet.ServletException"%>
<%@page import="javax.servlet.http.HttpServletRequest"%>
<%@page import="javax.servlet.http.HttpServletResponse"%>
<%@page import="org.apache.tomcat.util.http.fileupload.FileItem"%>
<%@page import="org.apache.tomcat.util.http.fileupload.FileUploadException"%>
<%@page import="org.apache.tomcat.util.http.fileupload.disk.DiskFileItemFactory"%>
<%@page import="org.apache.tomcat.util.http.fileupload.servlet.ServletFileUpload"%>
<%@page import="org.apache.tomcat.util.http.fileupload.servlet.ServletRequestContext"%>
<html>
<head>
<title>Dump</title>
<style type="text/css">
body {
	background-color: #CCFFCC;
	margin: 20px;
	padding: 0;
	font-family: "Verdana", sans-serif;
}

table {
	width: 100%;
	border-style: solid;
	border-width: 1px;
	border-color: black;
	border-collapse: collapse;
}

th {
	color: white;
	background-color: #666666; 
	border-style: solid;
	border-width: 1px;
	border-color: black;
	text-align: left;
	vertical-align: top;
	width: 20%;
	border-width: 1px;
	border-style: solid;
	padding: 3px;
}

th.header {
	text-align: center;
	vertical-align: middle;
}

td {
	color: black;
	background-color: #cccccc; 
	border-style: solid;
	border-width: 1px;
	border-color: black;
	text-align: left;
	vertical-align: top;
	width: 80%;
	padding: 3px;
}
</style>
</head>
<body>
<a id="request_headers"></a>
<table>
	<tr>
		<th colspan="2" class="header">REQUEST HEADERS</th>
	</tr>
	<%
		Enumeration<String> requestHeaders = request.getHeaderNames();
		while (requestHeaders.hasMoreElements()) {
			String header = requestHeaders.nextElement();
	%>
	<tr>
		<th><%=header%></th>
		<td><%=request.getHeader(header)%></td>
	</tr>
	<%
		}
	%>
</table>
<br/>
<a id="cgi_parameters"></a>
<table>
	<tr>
		<th colspan="2" class="header">CGI PARAMETERS</th>
	</tr>
	<%
		Enumeration<String> requestParams = request.getParameterNames();
		while (requestParams.hasMoreElements()) {
			String param = requestParams.nextElement();
	%>
	<tr>
		<th><%=param%></th>
		<td><%for(String value : request.getParameterValues(param)) {%><%=value %>&nbsp;<%}%></td>
	</tr>
	<%
		}
	%>
</table>
<br/>
<a id="multipart_parameters"></a>
<table>
	<tr>
		<th colspan="2" class="header">MULTIPART/FORM-DATA PARAMETERS</th>
	</tr>
	<%
		if (ServletFileUpload.isMultipartContent(request)) {
			final DiskFileItemFactory diskFileItemFactory = new DiskFileItemFactory();
			final ServletFileUpload servletFileUpload = new ServletFileUpload(diskFileItemFactory);
			try {
				final ServletRequestContext servletRequestContext = new ServletRequestContext(request);
				for (FileItem fileItem : servletFileUpload.parseRequest(servletRequestContext)) {
	%>
	<tr>
		<th><%=fileItem.getFieldName()%></th>
		<td><%=fileItem.isFormField()?fileItem.getString():fileItem.getName()%></td>
	</tr>
	<%
				}

			} catch (FileUploadException e) {
				throw new ServletException(e);
			}
		}
	%>
</table>
<br/>
<a id="request_attributes"></a>
<table>
	<tr>
		<th colspan="2" class="header">REQUEST ATTRIBUTES</th>
	</tr>
	<%
		Enumeration<String> requestAttrs = request.getAttributeNames();
		while (requestAttrs.hasMoreElements()) {
			String attribute = requestAttrs.nextElement();
	%>
	<tr>
		<th><%=attribute%></th>
		<td><%=request.getAttribute(attribute)%></td>
	</tr>
	<%
		}
	%>
</table>
<br/>
<a id="cookies"></a>
<table>
	<tr>
		<th colspan="2" class="header">COOKIES</th>
	</tr>
  <%
  try {
			for (Cookie cookie: request.getCookies()) {
	%>
  <tr>
		<th><%=cookie.getName() %></th>
		<td><%=cookie.getValue()%></td>
	</tr>
  <%
				}
			} catch (NullPointerException e) {
				// Do nothing
			}
  %>
</table>
<br/>
<a id="servlet_context"></a>
<table>
	<tr>
		<th colspan="2" class="header">SERVLET CONTEXT</th>
	</tr>
	<%
		ServletContext context = this.getServletContext();
		Enumeration<String> contextAttrs = context.getAttributeNames();
		while (contextAttrs.hasMoreElements()) {
			String attribute = contextAttrs.nextElement();
			Object value = context.getAttribute(attribute);
			if(attribute.matches(".*path$") && (value instanceof String)) {
				StringBuffer buffer = new StringBuffer();
				String [] paths = ((String) value).split(System.getProperty("path.separator"));
				for(String path : paths) {
					buffer.append(path);
					buffer.append("<br>");	
				}
				value = buffer.toString();
			}
			if("org.apache.catalina.WELCOME_FILES".equals(attribute)) {
				String[] welcomeFiles = (String[])value;
				StringBuffer buffer = new StringBuffer();
				for(String welcomeFile : welcomeFiles ) {
					buffer.append(welcomeFile);
					buffer.append("<br>");						
				}
				value = buffer.toString();
			}
	%>
	<tr>
		<th><%=attribute%></th>
		<td><%=value%></td>
	</tr>
	<%
		}
	%>
</table>

<a id="session"></a>
<table>
	<tr>
		<th colspan="2" class="header">SESSION</th>
	</tr>
	<%
	Enumeration<String> sessionAttrs = session.getAttributeNames();
		while (sessionAttrs.hasMoreElements()) {
			String attribute = sessionAttrs.nextElement();
			Object value = session.getAttribute(attribute);
	%>
	<tr>
		<th><%=attribute%></th>
		<td><%=value%></td>
	</tr>
	<%
		}
	%>
</table>
<br/>
<a id="basic_authentication"></a>
<table>
	<tr>
		<th colspan="2" class="header">BASIC AUTHENTICATION</th>
	</tr>
	<%
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
	%>
	<tr>
		<th>authorization</th>
		<td><%=authorization%></td>
	</tr>
	<tr>
		<th>login</th>
		<td><%=login%></td>
	</tr>
	<tr>
		<th>password</th>
		<td><%=password%></td>
	</tr>
	<%
		}
	%>
</table>
<br/>
<a id="remote_informations"></a>
<table>
	<tr>
		<th colspan="2" class="header">REMOTE INFORMATIONS</th>
	</tr>
	<tr>
		<th>RemoteAddr</th>
		<td><%=request.getRemoteAddr()%></td>
	</tr>
	<tr>
		<th>RemoteHost</th>
		<td><%=request.getRemoteHost()%></td>
	</tr>
	<tr>
		<th>RemotePort</th>
		<td><%=request.getRemotePort()%></td>
	</tr>
	<tr>
		<th>RemoteUser</th>
		<td><%=request.getRemoteUser()==null?"&nbsp;":request.getRemoteUser()%></td>
	</tr>
</table>
<br/>
<a id="miscaleneous"></a>
<table>
	<tr>
		<th colspan="2" class="header">MISCALENEOUS</th>
	</tr>
	<tr>
		<th>Secure</th>
		<td><%=request.isSecure()%></td>
	</tr>
	<tr>
		<th>Method</th>
		<td><%=request.getMethod()%></td>
	</tr>
	<tr>
		<th>Request URL</th>
		<td><%= request.getRequestURL().toString() %></td>
	</tr>
	<tr>
		<th>Scheme</th>
		<td><%=request.getScheme()%></td>
	</tr>
	<tr>
		<th>Protocol</th>
		<td><%=request.getProtocol()%></td>
	</tr>
	<tr>
		<th>Session Creation Time</th>
		<td><%=new SimpleDateFormat("dd-MMM-yyyy HH:mm:ss").format(session.getCreationTime())%></td>
	</tr>
	<tr>
		<th>Session Max Inactive Interval</th>
		<td><%=session.getMaxInactiveInterval()%></td>
	</tr>
	<tr>
		<th>Query String</th>
		<td><%=request.getQueryString()%></td>
	</tr>
	<tr>
		<th>Context Path</th>
		<td><%=getServletContext().getServletContextName()%></td>
	</tr>
	<tr>
		<th>Time Zone</th>
		<td><%=TimeZone.getDefault().getDisplayName()%></td>
	</tr>	
	<tr>
		<th>Servlet Context Path</th>
		<td><%=getServletContext().getRealPath("").toString()%></td>
	</tr>		
</table>
<br/>
<a id="system_properties"></a>
<table>
	<tr>
		<th colspan="2" class="header">SYSTEM PROPERTIES</th>
	</tr>
	<%
		TreeSet<String> systemProperties = new TreeSet<String>();
		for (Object o : System.getProperties().keySet()) systemProperties.add(o.toString()); 
		for (String property : systemProperties) {
			String value = System.getProperty(property);
			
			if(property.matches(".*\\.path$")||property.matches(".*\\.dirs$")) {
				StringBuffer buffer = new StringBuffer();
				String [] paths = value.split(System.getProperty("path.separator"));
				for(int i=0; i<paths.length; i++) {
					buffer.append(paths[i]);
					buffer.append("<br>");
				}
				value = buffer.toString();
			}
	%>
	<tr>
		<th><%=property%></th>
		<td><%=value%></td>
	</tr>
	<%
		}
	%>
</table>
</body>
</html>