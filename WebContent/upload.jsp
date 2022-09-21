<%@page trimDirectiveWhitespaces="true"%>
<%@page import="static java.io.File.separatorChar"%>
<%@page import="static java.text.MessageFormat.format"%>
<%@page import="static java.util.logging.Level.SEVERE"%>
<%@page import="java.io.File"%>
<%@page import="java.io.IOException"%>
<%@page import="java.io.PrintWriter"%>
<%@page import="java.util.List"%>
<%@page import="java.util.logging.Logger"%>
<%@page import="java.util.regex.Pattern"%>
<%@page import="org.apache.tomcat.util.http.fileupload.FileItem"%>
<%@page import="org.apache.tomcat.util.http.fileupload.FileUploadException"%>
<%@page import="org.apache.tomcat.util.http.fileupload.disk.DiskFileItem"%>
<%@page import="org.apache.tomcat.util.http.fileupload.disk.DiskFileItemFactory"%>
<%@page import="org.apache.tomcat.util.http.fileupload.servlet.ServletFileUpload"%>
<%@page import="org.apache.tomcat.util.http.fileupload.servlet.ServletRequestContext"%>
<% if("POST".equals(request.getMethod())) { doPost(request, response); return; } %>
<%!
File store(final HttpServletRequest request, final File sourceFile, final String filename) {
	final File targetDir = (File) getServletContext().getAttribute("jakarta.servlet.context.tempdir");
	final File targetFile = new File(targetDir, substitueNTFSReservedCharacters(filename));
	final Logger logger = Logger.getLogger(getClass().getName());
	if (targetFile.exists()) {
		boolean rc = sourceFile.delete();
		if(!rc) logger.warning(format("Unable to delete ''{0}''!", sourceFile));
	} else {
		boolean rc = sourceFile.renameTo(targetFile);
		if(rc) logger.info(format("Stored file ''{0}''", targetFile));
		else logger.warning(format("Can''t move ''{0}'' to ''{1}''!", sourceFile, targetFile));
	}
	return targetFile;
}
%>
<%!
@Override
protected void doPost(final HttpServletRequest request, final HttpServletResponse response) throws ServletException, IOException {
	final Logger logger = Logger.getLogger(getClass().getName());

	response.setHeader("Cache-Control", "no-cache");
	response.setHeader("Content-Type", "text/plain");
	final PrintWriter writer = response.getWriter();

	// Check if the request is multipart/form-data
	if (!ServletFileUpload.isMultipartContent(request)) {
		response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
		final String message = "Not a multipart/form-data submission!";
		logger.log(SEVERE, message);
		writer.write(message);
		return;
	}

	// Parse the multipart/form-data request
	final DiskFileItemFactory fileItemFactory = new DiskFileItemFactory();

	// Enforce the DeferredFileOutputStream to record on a temporary file
	fileItemFactory.setSizeThreshold(0);

	// Containment: record the temporary file in the servlet context temporary folder.
	final File tempDir = (File) getServletContext().getAttribute("jakarta.servlet.context.tempdir");
	fileItemFactory.setRepository(tempDir);

	final ServletFileUpload servletFileUpload = new ServletFileUpload(fileItemFactory);
	List<FileItem> items = null;
	try {
		final ServletRequestContext requestContext = new ServletRequestContext(request);
		items = servletFileUpload.parseRequest(requestContext);
	} catch (FileUploadException e) {
		throw new ServletException(e);
	}

	// Request parameters
	DiskFileItem binaryFileItem = null;

	// Retrieve the multipart/form-data parameters
	for (final FileItem item : items) {
		if (item.isFormField()) {
			// do nothing
		} else {
			if (item.getName() != null && new File(item.getName()).getName().length() > 0) {
				binaryFileItem = (DiskFileItem) item;
				break; // only the first file item will be handled!
			}
		}
	}

	// Check if a file has been provided
	if (binaryFileItem == null) {
		response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
		final String message = "No file has been provided!";
		logger.log(SEVERE, message);
		writer.write(message);
		return;
	}

	// Check if the file is not empty
	if (!binaryFileItem.getStoreLocation().exists()) {
		response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
		final String message = "File is empty!";
		logger.log(SEVERE, message);
		writer.write(message);
		return;
	}

	final File temporaryFile = binaryFileItem.getStoreLocation();

	String filename = binaryFileItem.getName();
	if(filename.lastIndexOf(separatorChar) != -1) {
		filename = filename.substring(filename.lastIndexOf(separatorChar)+1);
	}
	logger.info(format("Uploaded file ''{0}''", filename));
	final File targetFile = store(request, temporaryFile, filename);
	writer.println(targetFile.getAbsolutePath());
}
%>
<%!
private static String substitueNTFSReservedCharacters(final String input) {
	String result = input;

	final Pattern reservedCharactersPattern = Pattern.compile("[\\x00-\\x1F\\x22\\x2A\\x3A\\x3C\\x3E\\x3F\\x5C\\x7C]");

	if (reservedCharactersPattern.matcher(input).find()) {
		result = result.replace('"', (char) 0xa8 /* DIAERESIS */);
		result = result.replace('*', (char) 0xa4 /* CURRENCY SIGN */);
		result = result.replace('/', (char) 0xf8 /* LATIN SMALL LETTER O WITH STROKE */);
		result = result.replace(':', (char) 0xf7 /* DIVISION SIGN */);
		result = result.replace('<', (char) 0xab /* LEFT-POINTING DOUBLE ANGLE QUOTATION MARK */);
		result = result.replace('>', (char) 0xbb /* RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK */);
		result = result.replace('?', (char) 0xbf /* INVERTED QUESTION MARK */);
		result = result.replace('\\', (char) 0xff /* LATIN SMALL LETTER Y WITH DIAERESIS */);
		result = result.replace('|', (char) 0xa6 /* BROKEN BAR */);
		if (reservedCharactersPattern.matcher(input).find()) {
			// This can happen only if there are control characters, e.g '\t', '\f' ... this case is unlikely
			result = reservedCharactersPattern.matcher(result).replaceAll("\u00A0");
		}
	}
	return result;
}
%>
<html>
<head>
<title>Upload</title>
<link rel="stylesheet" href="main.css" type="text/css" />
</head>
<body>
<h1>Upload</h1>
<form method="post" ENCTYPE="multipart/form-data"
	action="<%= getServletContext().getContextPath() %>/upload.jsp">
<table>
	<tr>
		<th><label for="file">File</label><em>*</em></th>
		<td><input type="file" id="file" name="file" accept="*/*" size="40" /></td>
	</tr>
	<tr>
		<th>&nbsp;</th>
		<td><input type="submit" id="upload" value="upload" /></td>
		<td>&nbsp;</td>
	</tr>
</table>
</form>
</body>
</html>
