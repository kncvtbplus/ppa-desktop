package com.linksbridge.ppa.controller;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.security.Principal;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Properties;
import java.util.Set;
import java.util.UUID;
import java.util.Date;
import java.util.stream.Collectors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;

import javax.annotation.security.RolesAllowed;
import javax.persistence.Column;
import javax.persistence.EntityNotFoundException;
import javax.persistence.ManyToOne;
import javax.servlet.http.HttpServletRequest;

import org.apache.commons.io.FilenameUtils;
import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.ArrayUtils;
import org.apache.commons.lang3.StringUtils;
import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;
import org.joda.time.Duration;
import org.rosuda.REngine.REXP;
import org.rosuda.REngine.REXPInteger;
import org.rosuda.REngine.REXPMismatchException;
import org.rosuda.REngine.REXPString;
import org.rosuda.REngine.Rserve.RConnection;
import org.rosuda.REngine.Rserve.RserveException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.MessageSource;
import org.springframework.context.MessageSourceAware;
import org.springframework.context.NoSuchMessageException;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.amazonaws.AmazonClientException;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.model.GetObjectRequest;
import com.amazonaws.services.s3.model.ObjectMetadata;
import com.amazonaws.services.s3.model.S3Object;
import com.amazonaws.services.s3.transfer.TransferManager;
import com.amazonaws.services.s3.transfer.Upload;
import com.amazonaws.services.simpleemail.AmazonSimpleEmailService;
import com.amazonaws.services.simpleemail.model.Body;
import com.amazonaws.services.simpleemail.model.Content;
import com.amazonaws.services.simpleemail.model.Destination;
import com.amazonaws.services.simpleemail.model.Message;
import com.amazonaws.services.simpleemail.model.SendEmailRequest;
import com.google.common.collect.ImmutableMap;
import com.linksbridge.ppa.exceptionhandler.ApplicationException;
import com.linksbridge.ppa.model.Account;
import com.linksbridge.ppa.model.AccountUserAssociation;
import com.linksbridge.ppa.model.DataSource;
import com.linksbridge.ppa.model.Invitation;
import com.linksbridge.ppa.model.Metric;
import com.linksbridge.ppa.model.MetricType;
import com.linksbridge.ppa.model.Output;
import com.linksbridge.ppa.model.Ppa;
import com.linksbridge.ppa.model.PpaSector;
import com.linksbridge.ppa.model.PpaSectorDefaultValue;
import com.linksbridge.ppa.model.PpaSectorLevel;
import com.linksbridge.ppa.model.PpaSectorMapping;
import com.linksbridge.ppa.model.SubnationalUnit;
import com.linksbridge.ppa.model.SubnationalUnitMapping;
import com.linksbridge.ppa.model.User;
import com.linksbridge.ppa.model.UserFile;
import com.linksbridge.ppa.model.UserRole;
import com.linksbridge.ppa.repository.AccountRepository;
import com.linksbridge.ppa.repository.AccountUserAssociationRepository;
import com.linksbridge.ppa.repository.DataSourceRepository;
import com.linksbridge.ppa.repository.InvitationRepository;
import com.linksbridge.ppa.repository.MetricRepository;
import com.linksbridge.ppa.repository.MetricTypeRepository;
import com.linksbridge.ppa.repository.OutputRepository;
import com.linksbridge.ppa.repository.PpaRepository;
import com.linksbridge.ppa.repository.PpaSectorDefaultValueRepository;
import com.linksbridge.ppa.repository.PpaSectorLevelRepository;
import com.linksbridge.ppa.repository.PpaSectorMappingRepository;
import com.linksbridge.ppa.repository.PpaSectorRepository;
import com.linksbridge.ppa.repository.SubnationalUnitMappingRepository;
import com.linksbridge.ppa.repository.SubnationalUnitRepository;
import com.linksbridge.ppa.repository.UserFileRepository;
import com.linksbridge.ppa.repository.UserRepository;
import com.linksbridge.ppa.user.MyUserDetails;
import com.linksbridge.ppa.util.Common;
import com.linksbridge.ppa.controller.PpaExportDto;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

@RestController(value = "dataController")
@RequestMapping("/data")
@RolesAllowed({"ROLE_USER"})
public class DataController implements MessageSourceAware
{
	@SuppressWarnings("unused")
	private static final Logger logger = LoggerFactory.getLogger(DataController.class);
	
	private static final String ROLE_USER = "ROLE_USER";
	private static final String ROLE_ADMIN = "ROLE_ADMIN";
	private static final String GUEST_USERNAME = "guest@ppa-desktop";
	
	private static final String FILE_TABLE_NAME_PREFIX = "z_file_content";
	private static final String FILE_TABLE_ROW_NUMBER_COLUMN_NAME = "row.names";
	private static final int FILE_TABLE_COLUMN_LIMIT = 1000;
	
	private static final String PPA_AGGREGATION_LEVEL_NATIONAL = "National";
	
	private static final String DATA_SOURCE_GLOBAL_VARIABLE_FACILITY_TYPE = "facilityType";
	private static final String DATA_SOURCE_GLOBAL_VARIABLE_FACILITY_TYPE_NAME = "Facility Type";
	private static final String DATA_SOURCE_GLOBAL_VARIABLE_HEALTH_SECTOR = "healthSector";
	private static final String DATA_SOURCE_GLOBAL_VARIABLE_HEALTH_SECTOR_NAME = "Health Sector";
	private static final String DATA_SOURCE_GLOBAL_VARIABLE_SUBNATIONAL_UNIT = "subnationalUnit";
	
	// date format
	
	SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
	
	// local / offline mode flag
	// When true, registration, invitations and email-based flows are disabled
	// and the app is expected to be used as a single local installation.
	@Value("${local.mode:false}")
	private boolean localMode;
	
	// home path
	
	@Value("${home.path}")
	private String homePath;
	
	// token
	
	@Value("${token.key}")
	private String tokenKey;
	
	@Value("${token.timeout.seconds}")
	private long tokenTimeoutSeconds;
	
	// confirmEmail
	
	@Value("${confirmemail.key}")
	private String confirmEmailKey;
	
	// acceptInvitation
	
	@Value("${acceptinvitation.key}")
	private String acceptInvitationKey;
	
	// resetPassword
	
	@Value("${resetpassword.key}")
	private String resetPasswordKey;
	
	// messages.properties.path
	
	@Value("${messages.properties.path}")
	private String messagesPropertiesPath;
	
	// request
	
	@Autowired
	private HttpServletRequest httpServletRequest;
	
	// jdbcTemplate
	
    @Autowired
    JdbcTemplate jdbcTemplate;

	// Map.Entry<String, ?> key comparator
	
	Comparator<Map.Entry<String, ? extends Object>> mapEntryKeyComparator = new Comparator<Map.Entry<String,? extends Object>>()
	{
		@Override
		public int compare(Map.Entry<String, ? extends Object> o1, Map.Entry<String, ? extends Object> o2)
		{
			return o1.getKey().compareTo(o2.getKey());
			
		}
		
	}
	;
	
	// R list separator
	
	private static final char R_LIST_SEPARATOR = ',';

	// Export/import schema version for .ppa files
	private static final int PPA_EXPORT_SCHEMA_VERSION = 1;
	
	// R file type read commands
	
	private static final Map<String, String> rFileTypeReadCommands = new HashMap<>();
	static
	{
		rFileTypeReadCommands.put("csv", "read.csv('%s', fileEncoding = \"UTF-8\", stringsAsFactors = FALSE, header = TRUE)");
		rFileTypeReadCommands.put("dta", "read.dta('%s', convert.factors = FALSE)");
		
	}
	
	// output formats
	
	private static final String EXCEL_OUTPUT_FILE_EXTENSION = ".xlsx";
	private static final String PNG_OUTPUT_FILE_EXTENSION = ".png";
	
	// message source
	
	private MessageSource messageSource;

	private final ObjectMapper objectMapper = new ObjectMapper();

	public void setMessageSource(MessageSource messageSource)
	{
		this.messageSource = messageSource;
	}
	
	// passwordEncoder
	
	@Autowired
	private PasswordEncoder passwordEncoder;
	
	// AWS clients
	
	@Autowired
	private AmazonS3 amazonS3;
	
	@Autowired
	private TransferManager transferManager;
	
	@Autowired
	private AmazonSimpleEmailService amazonSimpleEmailService;
	
	// session timeout
	
	@Value("${server.servlet.session.timeout}")
	private int sessionTimeout;
	
	// AWS S3
	
	@Value("${s3.bucket}")
	private String s3Bucket;
	
	@Value("${s3.mount}")
	private String s3Mount;

	// In local/offline setups the app and Rserve may not share the same filesystem.
	// These properties allow mapping a host path (used by Java file IO) to an Rserve
	// path (used inside R commands). By default both fall back to s3.mount.
	@Value("${s3.mount.host:${s3.mount}}")
	private String s3MountHost;

	@Value("${s3.mount.r:${s3.mount}}")
	private String s3MountR;
	
	@Value("${s3.rscript.key}")
	private String s3RScriptKey;
	
	@Value("${s3.userfile.directory}")
	private String s3UserFileDirectory;
	
	@Value("${s3.output.directory}")
	private String s3OutputDirectory;
	
	// Rserve
	
	@Value("${rserve.host}")
	private String rServeHost;
	
	@Value("${rserve.port}")
	private Integer rServePort;
	
	// database
	
	@Value("${spring.datasource.host}")
	private String datasourceHost;
	
	@Value("${spring.datasource.port}")
	private String datasourcePort;
	
	@Value("${spring.datasource.database}")
	private String datasourceDatabase;
	
	@Value("${spring.datasource.username}")
	private String datasourceUsername;
	
	@Value("${spring.datasource.password}")
	private String datasourcePassword;
	
	// repositories
	
	@Autowired
	private InvitationRepository invitationRepository;
	
	@Autowired
	private UserRepository userRepository;
	
	@Autowired
	private AccountRepository accountRepository;
	
	@Autowired
	private AccountUserAssociationRepository accountUserAssociationRepository;
	
	@Autowired
	private UserFileRepository userFileRepository;
	
	@Autowired
	private DataSourceRepository dataSourceRepository;
	
	@Autowired
	private MetricTypeRepository metricTypeRepository;
	
	@Autowired
	private MetricRepository metricRepository;
	
	@Autowired
	private PpaSectorDefaultValueRepository ppaSectorDefaultValueRepository;
	
	@Autowired
	private PpaSectorRepository ppaSectorRepository;
	
	@Autowired
	private PpaSectorLevelRepository ppaSectorLevelRepository;
	
	@Autowired
	private PpaSectorMappingRepository ppaSectorMappingRepository;
	
	@Autowired
	private SubnationalUnitRepository subnationalUnitRepository;
	
	@Autowired
	private SubnationalUnitMappingRepository subnationalUnitMappingRepository;
	
	@Autowired
	private OutputRepository outputRepository;
	
	@Autowired
	private PpaRepository ppaRepository;
	
	// ====================================================================================================
	// utilities
	// ====================================================================================================
	
	/**
	 * Gets message for code and parameters.
	 * 
	 * @param code
	 * @param parameters
	 * @param locale
	 * @return
	 */
	private String getMessageText(String code, String[] parameters)
	{
		String message;

		try
		{
			message = messageSource.getMessage(code, parameters, LocaleContextHolder.getLocale());

		}
		catch (NoSuchMessageException e)
		{
			message = code;

		}
		
		return message;

	}
	
	/**
	 * Returns Rserve connection.
	 * 
	 */
	private RConnection getRserveConnection()
	{
		RConnection rConnection = null;
		
        try
		{
			rConnection = new RConnection(rServeHost);
//			rConnection.setStringEncoding("UTF-8");
			
		}
		catch (Throwable e)
		{
			e.printStackTrace();
	        throw new ApplicationException("Cannot connect to Rserve.");
	        
		}
		
		return rConnection;
		
	}
	
	/**
	 * Tests Rserve connection.
	 * Throws an exception if Rserve is not accessible.
	 * 
	 */
	private void testRserveConnection()
	{
		RConnection rConnection = null;
		
		try
		{
	        try
			{
				rConnection = getRserveConnection();
				
			}
			catch (Throwable e)
			{
				e.printStackTrace();
		        throw new ApplicationException("Cannot connect to Rserve.");
		        
			}
	        
		}
		finally
		{
			if (rConnection != null) rConnection.close();
			
		}
			
	}
	
	/**
	 * Evaluates code in R and prints error if any.
	 * 
	 * @param code
	 * @return
	 */
	private REXP rEval(RConnection rConnection, String code)
	{
		System.out.println(code);
		
		REXP rexp;
		try
		{
			rexp = rConnection.eval(String.format("try(%s, silent=TRUE)", code));
			if (rexp.inherits("try-error"))
			{
				System.err.println("Error: "+rexp.asString());
				throw new ApplicationException(rexp.asString());
				
			}
			
		}
		catch (RserveException | REXPMismatchException  e)
		{
			e.printStackTrace();
			throw new ApplicationException(e);
			
		}
		
		return rexp;

	}
	
	/**
	 * Evaluates code in R and prints error if any.
	 * 
	 * @param code
	 * @return
	 */
	private void rPopulateList(RConnection rConnection, String list, String[] values, boolean quoted)
	{
		String[] preparedValues = (quoted ? quoteValues(values) : values);
		
		rEval(rConnection, String.format("%s <- c(%s)", list, StringUtils.join(preparedValues, R_LIST_SEPARATOR)));

	}
	
	/**
	 * Quotes string values in the array.
	 * 
	 * @param values
	 * @return
	 */
	private String[] quoteValues(String[] values)
	{
		String[] quotedValues = new String[values.length];
		
		for (int i = 0; i < values.length; i++)
		{
			quotedValues[i] = new StringBuilder().append('"').append(values[i].replace("\"", "\\\"")).append('"').toString();
			
		}
		
		return quotedValues;

	}
	
	private String buildPpaSectorLevelText(String ppaSectorName, String ppaSectorLevel)
	{
		return String.format("%s [%s]", ppaSectorName, ppaSectorLevel);
		
	}
	
	private String joinMountAndKey(String mount, String s3Key)
	{
		if (mount == null) mount = "";
		if (s3Key == null) s3Key = "";
		
		String m = mount.endsWith("/") ? mount.substring(0, mount.length() - 1) : mount;
		String k = s3Key.startsWith("/") ? s3Key.substring(1) : s3Key;
		
		return String.format("%s/%s", m, k);
	}

	private String toRPath(String path)
	{
		// R understands forward slashes on all platforms; this avoids backslash escaping issues.
		return path == null ? null : path.replace('\\', '/');
	}

	private String escapeRStringLiteral(String value)
	{
		if (value == null) return "";
		return value.replace("\\", "\\\\").replace("\"", "\\\"");
	}

	private String getS3MountPath(String s3Key)
	{
		// Host path for Java IO (LOCAL_MODE writes/reads here).
		return joinMountAndKey(s3MountHost, s3Key);

	}

	private String getS3MountPathR(String s3Key)
	{
		// Rserve path used inside R commands.
		return toRPath(joinMountAndKey(s3MountR, s3Key));

	}
	
	private String getS3Key(String prefix, String name)
	{
		return String.format("%s/%s", prefix, name);
		
	}

	/**
	 * Reads a file that is normally stored in S3. For backwards compatibility
	 * this first tries S3 and, if that fails (for example in a local/offline
	 * environment without S3 access), falls back to reading from the local
	 * s3 mount path (e.g. /s3/output/...).
	 */
	private byte[] readBytesFromS3OrLocal(String s3Key, String errorContext)
	{
		// In local/offline mode we skip S3 entirely and go straight to the shared
		// /s3 mount (mapped to a local folder by docker-compose / the installer).
		if (localMode)
		{
			try
			{
				Path localPath = Paths.get(getS3MountPath(s3Key));
				return Files.readAllBytes(localPath);
			}
			catch (IOException ioException)
			{
				throw new ApplicationException(
						String.format("Cannot read %s from local path '%s'.", errorContext, getS3MountPath(s3Key)),
						ioException);
			}
		}

		// Default behaviour (cloud / production): try S3 first, then fall back to
		// the local /s3 mount if that fails (for example in an offline dev setup).
		try
		{
			S3Object s3Object = amazonS3.getObject(new GetObjectRequest(s3Bucket, s3Key));
			return IOUtils.toByteArray(s3Object.getObjectContent());
			
		}
		catch (AmazonClientException | IOException e)
		{
			// Fall back to local filesystem using the configured s3 mount.
			try
			{
				Path localPath = Paths.get(getS3MountPath(s3Key));
				return Files.readAllBytes(localPath);
				
			}
			catch (IOException ioException)
			{
				throw new ApplicationException(
						String.format("Cannot read %s from S3 or local path.", errorContext),
						ioException);
				
			}
			
		}
	}

	/**
	 * Very small helper to make file names safe for use in the Content-Disposition
	 * header and inside ZIP entries.
	 */
	private String sanitizeFileName(String name)
	{
		if (name == null)
		{
			return "ppa";
		}
		
		// Replace path separators and trim whitespace.
		String sanitized = name.replace('\\', '_').replace('/', '_').trim();
		
		// Allow only a conservative set of characters.
		sanitized = sanitized.replaceAll("[^A-Za-z0-9._-]", "_");
		
		if (sanitized.isEmpty())
		{
			return "ppa";
		}
		
		return sanitized;
	}

	private User getUser()
	{
		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
		
		if (authentication instanceof AnonymousAuthenticationToken)
		{
			throw new IllegalStateException("Cannot get user information for not authenticated user.");
			
		}
		
	    String userName = authentication.getName();
	    
		User user = userRepository.findByUsername(userName);
		
	    return user;
		
	}

	private AccountUserAssociation getAccountUserAssociation(Account account, User user)
	{
		return accountUserAssociationRepository.findByAccountAndUser(account, user);
		
	}

	private boolean isUserAccountAdministrator(Account account, User user)
	{
		// get accountUserAssociation
		
		AccountUserAssociation accountUserAssociation = accountUserAssociationRepository.findByAccountAndUser(account, user);
		
		// return administrator
		
		return accountUserAssociation.getAdministrator();
		
	}

	private boolean isGuestUser(User user)
	{
		return GUEST_USERNAME.equals(user.getUsername());
	}

	private void assertNotGuestUser(User user)
	{
		if (isGuestUser(user))
		{
			throw new ApplicationException("The guest user cannot be modified or removed.");
		}
	}

	private void assertAccountAdministrator(Account account)
	{
		// get user
		
		User user = getUser();
		
		// get accountUserAssociation
		
		AccountUserAssociation accountUserAssociation = accountUserAssociationRepository.findByAccountAndUser(account, user);
		
		// assert administrator
		
		if (!accountUserAssociation.getAdministrator())
		{
			throw new ApplicationException("Current user is not an administrator of given account. Operation is not authorized.");
			
		}
		
	}

	private Ppa getSelectedPpa(boolean assertNotNull)
	{
		// get user
		
		User user = getUser();
		
		// get selected account
		
		Account selectedAccount = user.getSelectedAccount();
		
		// assert selected account is not null
		
		if (selectedAccount == null)
		{
			throw new ApplicationException(getMessageText("system.accountRequired.message", new String[] {}));
			
		}
		
		// get account user association
		
		AccountUserAssociation selectedAccountUserAssociation = accountUserAssociationRepository.findByAccountAndUser(selectedAccount, user);
		
		// get selected PPA
		
		Ppa selectedPpa = selectedAccountUserAssociation.getSelectedPpa();
		
		// assert selected PPA is not null if requires
		
		if (assertNotNull && selectedPpa == null)
		{
			throw new ApplicationException(getMessageText("system.ppaRequired.message", new String[] {}));
			
		}
		
		// return selected PPA
		
		return selectedPpa;

	}

	private void createDefaultPpaMetrics
	(
			Ppa ppa
	)
	{
		// get existing metric Ids
		
		Set<Long> existingMetricTypeIds = new HashSet<>();
		
		for (Metric ppaMetric : ppa.getMetrics())
		{
			existingMetricTypeIds.add(ppaMetric.getMetricType().getId());
			
		}
		
		// create default metrics
		
		for (MetricType metricType : metricTypeRepository.findAllByOrderByIdAsc())
		{
			if (!existingMetricTypeIds.contains(metricType.getId()))
			{
				Metric metric = new Metric();
				ppa.addMetric(metric);
				
				metric.setMetricType(metricType);
				metric.setDataPointName(metricType.getName());
				
				// set selected for required metrics
				
				if (metricType.getRequired())
				{
					metric.setSelected(true);
					
				}
				
			}
			
		}
		
	}
	
	private UserFile getUserFile(Long id)
	{
		Optional<UserFile> optionalUserFile = userFileRepository.findById(id);
		
		if (!optionalUserFile.isPresent())
		{
			throw new ApplicationException("Cannot find userFile with id=" + id + ".");
			
		}
		
		return optionalUserFile.get();
		
	}
	
	private DataSource getDataSource(Long id)
	{
		Optional<DataSource> optionalDataSource = dataSourceRepository.findById(id);
		
		if (!optionalDataSource.isPresent())
		{
			throw new ApplicationException("Cannot find dataSource with id=" + id + ".");
			
		}
		
		return optionalDataSource.get();
		
	}
	
	private DataSource getPpaUserFileDataSource(Long ppaId, Long userFileId)
	{
		Optional<DataSource> optionalDataSource = dataSourceRepository.findByPpaIdAndUserFileId(ppaId, userFileId);
		
		return (optionalDataSource.isPresent() ? optionalDataSource.get() : null);
		
	}
	
//	/**
//	 * Extracts dataSource column values from original file via R.
//	 * 
//	 * @param dataSource
//	 * @param columnName
//	 * @param subset
//	 * @return
//	 */
//	private String[] extractDataSouceColumnValues(DataSource dataSource, String columnName, boolean subset)
//	{
//		String dataSourceFileName = dataSource.getUserFile().getFileName();
//		String dataSourceFileExtension = FilenameUtils.getExtension(dataSourceFileName).toLowerCase();
//		String dataSourceS3MountPath = getS3MountPath(dataSource.getUserFile().getS3FileName());
//		
//		RConnection rConnection = null;
//		try
//		{
//			rConnection = getRserveConnection();
//			
//			// load foreign library
//			
//			rEval(rConnection, "library('foreign')");
//			
//			// read data frame
//			
//			rEval(rConnection, "df<-" + String.format(rFileTypeReadCommands.get(dataSourceFileExtension), dataSourceS3MountPath));
//			
//			// subset rows
//			
//			if (subset)
//			{
//				if (StringUtils.isNotEmpty(dataSource.getSubsetColumn1Name()))
//				{
//					rPopulateList(rConnection, "Column.Values", dataSource.getSubsetColumn1SelectedValues(), true);
//					
//					rEval
//					(
//							rConnection,
//							String.format
//							(
//									"df <- df[df[[\"%s\"]] %%in%% Column.Values, ]",
//									dataSource.getSubsetColumn1Name()
//							)
//					)
//					;
//					
//				}
//				
//				if (StringUtils.isNotEmpty(dataSource.getSubsetColumn2Name()))
//				{
//					rPopulateList(rConnection, "Column.Values", dataSource.getSubsetColumn2SelectedValues(), true);
//					
//					rEval
//					(
//							rConnection,
//							String.format
//							(
//									"df <- df[df[[\"%s\"]] %%in%% Column.Values, ]",
//									dataSource.getSubsetColumn2Name()
//							)
//					)
//					;
//					
//				}
//				
//			}
//			
//			// extract column values
//			
//			String[] columnValues = rEval(rConnection, String.format("as.character(df[[\"%s\"]])", columnName)).asStrings();
//			
//			return columnValues;
//			
//		}
//		catch (REXPMismatchException e)
//		{
//			throw new ApplicationException("Cannot read data from column: " + dataSourceFileName + " " + columnName + ".", e);
//			
//		}
//        finally
//        {
//			if (rConnection != null) rConnection.close();
//
//        }
//		
//	}
//
	/**
	 * Returns file table name for given userFile and sectionIndex.
	 * 
	 * @return
	 */
	private String getFileTableName(long userFileId, int sectionIndex)
	{
		return String.format("%s_%d_%d", FILE_TABLE_NAME_PREFIX, userFileId, sectionIndex);
		
	}
	
	/**
	 * Return table sectionIndex for given columnIndex.
	 * 
	 * @param columnIndex
	 * @return
	 */
	private int getColumnSectionIndex(int columnIndex)
	{
		return columnIndex / FILE_TABLE_COLUMN_LIMIT;
		
	}
	
	/**
	 * Return table columnIndexRange for given sectionIndex.
	 * 
	 * @param sectionIndex
	 * @return
	 */
	private int[] getSectionColumnIndexRange(int sectionIndex)
	{
		return new int[] {sectionIndex * FILE_TABLE_COLUMN_LIMIT, (sectionIndex + 1) * FILE_TABLE_COLUMN_LIMIT, };
		
	}
	
	/**
	 * Extracts dataSource columns value frequencies from database table possibly subsetted.
	 * 
	 * @param dataSource
	 * @param columnName
	 * @param subsetted
	 * @return
	 */
	private Map<String, Long> extractDataSouceColumnValueFrequencies(DataSource dataSource, String columnName, boolean subsetted)
	{
		return extractDataSouceColumnValueCombinationFrequencies(dataSource, new String[] {columnName,  }, subsetted);
		
	}

	/**
	 * Extracts dataSource columns value combination frequencies from database table possibly subsetted.
	 * 
	 * @param dataSource
	 * @param columnNames
	 * @param subsetted
	 * @return
	 */
	private Map<String, Long> extractDataSouceColumnValueCombinationFrequencies(DataSource dataSource, String[] columnNames, boolean subsetted)
	{
		// check columnNames count
		
		if (columnNames.length == 0)
		{
			throw new IllegalArgumentException("No column names is given for extractDataSouceColumnValueCombinationFrequencies method.");
			
		}
		
		// return value
		
		Map<String, Long> subsetedColumnValueCombinationFrequencies = new LinkedHashMap<>();
		
		// clause builder holders
		
		Set<String> tables = new HashSet<>();
		String selectValue;
		List<String> conditions = new ArrayList<>();
		List<Object> parameters = new ArrayList<>();
		
		// get userFile
		
		UserFile userFile = dataSource.getUserFile();
		
		// get column file name
		
		for (String columnName : columnNames)
		{
			if (StringUtils.isNotEmpty(columnName))
			{
				String columnTableName = getColumnTableName(userFile, columnName);
				
				tables.add(columnTableName);
				
			}
			
		}
		
		// return empty map if there are no not empty columns
		
		if (tables.size() == 0)
		{
			return new HashMap<String, Long>();
			
		}
		
		// build select value
		
		List<String> selectColumns = new ArrayList<>();
		
		for (String columnName : columnNames)
		{
			if (StringUtils.isNotEmpty(columnName))
			{
				selectColumns.add(String.format("\"%s\"", columnName));
				
			}
			else
			{
				selectColumns.add("''");
				
			}
			
		}
		
		selectValue = StringUtils.join(selectColumns, String.format(" || '%s' || ", Common.TOKEN_SEPARATOR));
		
		// build conditions
		
		String subsetColumn1Name = dataSource.getSubsetColumn1Name();
		if (subsetted && StringUtils.isNotEmpty(subsetColumn1Name))
		{
			String[] subsetColumn1SelectedValues = dataSource.getSubsetColumn1SelectedValues();
			
			// return empty list if no values subsetted
			
			if (subsetColumn1SelectedValues.length == 0)
			{
				return new HashMap<String, Long>();
				
			}
			
			String subsetColumn1TableName = getColumnTableName(userFile, subsetColumn1Name);
			
			tables.add(subsetColumn1TableName);
			
			conditions.add
			(
					String.format
					(
							"\"%s\".\"%s\" in (%s)",
							subsetColumn1TableName,
							subsetColumn1Name,
							StringUtils.repeat("?", ",", subsetColumn1SelectedValues.length)
					)
			)
			;
			
			parameters.addAll(Arrays.asList(subsetColumn1SelectedValues));
			
		}
		
		String subsetColumn2Name = dataSource.getSubsetColumn2Name();
		if (subsetted && StringUtils.isNotEmpty(subsetColumn2Name))
		{
			String[] subsetColumn2SelectedValues = dataSource.getSubsetColumn2SelectedValues();
			
			// return empty list if no values subsetted
			
			if (subsetColumn2SelectedValues.length == 0)
			{
				return new HashMap<String, Long>();
				
			}
			
			String subsetColumn2TableName = getColumnTableName(userFile, subsetColumn2Name);
			
			tables.add(subsetColumn2TableName);
			
			conditions.add
			(
					String.format
					(
							"\"%s\".\"%s\" in (%s)",
							subsetColumn2TableName,
							subsetColumn2Name,
							StringUtils.repeat("?", ",", subsetColumn2SelectedValues.length)
					)
			)
			;
			
			parameters.addAll(Arrays.asList(subsetColumn2SelectedValues));
			
		}
		
		List<String> tableList = new ArrayList<>(tables);
		String fromTable = tableList.remove(0);
		StringBuilder tableStringBuilder = new StringBuilder(String.format(" from \"%s\"", fromTable));
		
		for (String joinTable : tableList)
		{
			tableStringBuilder.append
			(
					String.format
					(
							" join \"%s\" on (\"%s\".\"%s\") = (\"%s\".\"%s\")",
							joinTable,
							joinTable,
							FILE_TABLE_ROW_NUMBER_COLUMN_NAME,
							fromTable,
							FILE_TABLE_ROW_NUMBER_COLUMN_NAME
					)
			)
			;
			
		}
		
		String tableString = tableStringBuilder.toString();
		
		String conditionString = (conditions.size() == 0 ? "" : " where " + StringUtils.join(conditions, " and "));
		
		// extract value frequencies
		
		String sql =
				String.format
				(
						"select"
						+ " \"value\", count(*) \"frequency\""
						+ " from"
						+ " ("
						+ " select"
						+ " %s \"value\""
						+ tableString
						+ conditionString
						+ " ) \"q\""
						+ " group by \"value\""
						,
						selectValue
				)
		;
		
		List<Map<String, Object>> valueFrequencyEntries =
				jdbcTemplate.queryForList
				(
						sql,
						parameters.toArray(new Object[] {})
				)
		;
		
		// build column frequencies
		
		for (Map<String, Object> valueFrequencyEntry : valueFrequencyEntries)
		{
			subsetedColumnValueCombinationFrequencies.put(String.valueOf(valueFrequencyEntry.get("value")), (Long)valueFrequencyEntry.get("frequency"));
			
		}
		
		return subsetedColumnValueCombinationFrequencies;
		
	}

	private Object cloneEntity(Object oldEntity)
	{
		try
		{
			// get entity class
			
			Class<? extends Object> entityClass = oldEntity.getClass();
			
			// build methods map
			
			Map<String, Method> declaredMethods = new HashMap<>();
			
			for (Method method : entityClass.getDeclaredMethods())
			{
				String methodName = method.getName();
				
				if (declaredMethods.containsKey(methodName))
				{
					throw new ApplicationException("Entity \"" + entityClass + "\" contains duplicate method name \"" + methodName + "\".");
					
				}
				
				declaredMethods.put(methodName, method);
				
			}
			
			// create new entity
			
			Object newEntity = entityClass.newInstance();
			
			// clone instance values
			
			for (Field field : entityClass.getDeclaredFields())
			{
				// only columns and foreight keys
				
				if (field.isAnnotationPresent(Column.class) || field.isAnnotationPresent(ManyToOne.class))
				{
					// get field name
					
					String fieldName = field.getName();
					
					// get corresponding getMethod
					
					String getMethodName = "get" + fieldName.substring(0, 1).toUpperCase() + fieldName.substring(1);
					
					if (!declaredMethods.containsKey(getMethodName))
					{
						throw new ApplicationException("Entity \"" + entityClass + "\" does not contains method \"" + getMethodName + "\".");
						
					}
					
					Method getMethod = declaredMethods.get(getMethodName);
					
					// get corresponding setMethod
					
					String setMethodName = "set" + fieldName.substring(0, 1).toUpperCase() + fieldName.substring(1);
					
					if (!declaredMethods.containsKey(setMethodName))
					{
						throw new ApplicationException("Entity \"" + entityClass + "\" does not contains method \"" + setMethodName + "\".");
						
					}
					
					Method setMethod = declaredMethods.get(setMethodName);
					
					// copy value
					
					setMethod.invoke(newEntity, getMethod.invoke(oldEntity));
					
				}
				
			}
			
			return newEntity;
			
		}
		catch (SecurityException | InstantiationException | IllegalAccessException | IllegalArgumentException | InvocationTargetException e)
		{
			throw new ApplicationException(e);
			
		}
		
	}
	
	private void sendEmail(String to, String subject, String message)
	{
		// In local/offline mode we do not send real emails; just log and return.
		if (localMode)
		{
			logger.info("LOCAL_MODE is enabled – skipping email to '{}' with subject '{}'.", to, subject);
			return;
		}

		Locale locale = LocaleContextHolder.getLocale();
		
		SendEmailRequest request =
				new SendEmailRequest()
				.withSource
				(
						messageSource.getMessage("email.from", new String[] {}, locale)
				)
				.withDestination
				(
						new Destination()
						.withToAddresses(to)
				)
				.withMessage
				(
						new Message()
						.withSubject
						(
								new Content().withCharset("UTF-8").withData(subject)
						)
						.withBody
						(
								new Body()
								.withHtml
								(
										new Content().withCharset("UTF-8").withData(message)
								)
						)
				)
		;
		
		amazonSimpleEmailService.sendEmail(request);
		
	}
	
	private void sendConfirmationEmail(User user)
	{
		// create confirmation token
		
		String registerUserToken = UUID.randomUUID().toString();
		
		// store confirmation token
		
		user.setRegisterUserToken(registerUserToken);
		user.setRegisterUserTokenCreated(DateTime.now());
		
		// build confirmationUrl
		
		String confirmationUrl =
				String.format
				(
						"%s://%s:%d/%s?%s&%s=%s",
						httpServletRequest.getScheme(),
						httpServletRequest.getServerName(),
						httpServletRequest.getServerPort(),
						homePath,
						confirmEmailKey,
						tokenKey,
						registerUserToken
				)
		;
		
		// send message
		
		sendEmail(user.getEmail(), getMessageText("email.confirmation.subject", new String[] {}), getMessageText("email.confirmation.message", new String[] {confirmationUrl, }));
		
	}
	
	private void sendInvitationEmail(String to, String accountName, String registrationUrl)
	{
		// NWL clean this up and put the 'Space name' in de email subject.
		String subject = getMessageText("email.invitation.subject", new String[] {accountName});
		String message = getMessageText("email.invitation.message", new String[] {accountName, registrationUrl });
		sendEmail(to, subject, message);
	}
	
	private void setResetPasswordTokenAndSendEmail(User user)
	{
		// generate resetPasswordToken
		
		String token = UUID.randomUUID().toString();
		
		// update user record
		
		user.setResetPasswordToken(token);
		user.setResetPasswordTokenCreated(DateTime.now());
		
		// build resetPasswordUrl
		
		String resetPasswordUrl =
				String.format
				(
						"%s://%s:%d/%s?%s&%s=%s",
						httpServletRequest.getScheme(),
						httpServletRequest.getServerName(),
						httpServletRequest.getServerPort(),
						homePath,
						resetPasswordKey,
						tokenKey,
						token
				)
		;
		
		// send resetPassword email
		
		sendEmail
		(
				user.getEmail(),
				getMessageText("email.resetPassword.subject", new String[] {}),
				getMessageText("email.resetPassword.message", new String[] {user.getUsername(), resetPasswordUrl, })
		)
		;
		
	}
	
	private Metric getMetric(Long metricId)
	{
		Optional<Metric> optionalMetric = metricRepository.findById(metricId);
		
		if (!optionalMetric.isPresent())
		{
			throw new ApplicationException("User metric is not found with given id: " + metricId + ".");
			
		}
		
		Metric metric = optionalMetric.get();
		
		return metric;
		
	}
	
	private Set<DataSource> getPpaAssociatedDataSources(Ppa ppa)
	{
		Set<DataSource> ppaAssociatedDataSources = new LinkedHashSet<>();
		
		// get ppa dataSources
		
		for (DataSource dataSource : ppa.getDataSources())
		{
			if (dataSource.getMetrics().size() >= 1)
			{
				ppaAssociatedDataSources.add(dataSource);
				
			}
			
		}
		
		return ppaAssociatedDataSources;
		
	}
	
	@Transactional
	private void updateSubsetBasedValues(DataSource dataSource)
	{
		// get PPA
		
		Ppa selectedPpa = dataSource.getPpa();
		
		// HealthSector
		
		if (StringUtils.isNotEmpty(dataSource.getHealthSectorColumnName()))
		{
			// extract values
			
			Map<String, Long> healthSectorValueFrequencies = extractDataSouceColumnValueFrequencies(dataSource, dataSource.getHealthSectorColumnName(), true);
			
			// set valueFrequencies
			
			dataSource.setHealthSectorValueFrequencies(healthSectorValueFrequencies);
			
		}
		
		// FacilityType
		
		if (StringUtils.isNotEmpty(dataSource.getFacilityTypeColumnName()))
		{
			// extract values
			
			Map<String, Long> facilityTypeValueFrequencies = extractDataSouceColumnValueFrequencies(dataSource, dataSource.getFacilityTypeColumnName(), true);
			
			// set values and valueFrequencies
			
			dataSource.setFacilityTypeValueFrequencies(facilityTypeValueFrequencies);
			
		}
		
		// generate ppaSectorMappingValueCombinationFrequencies
		dataSource.setPpaSectorMappingValueCombinationFrequencies
		(
				extractDataSouceColumnValueCombinationFrequencies
				(
						dataSource,
						new String[] {dataSource.getHealthSectorColumnName(), dataSource.getFacilityTypeColumnName(), },
						true
				)
		)
		;
		
		// SubnationalUnit
		
		if (StringUtils.isNotEmpty(dataSource.getSubnationalUnitColumnName()))
		{
			// extract values
			
			Map<String, Long> subnationalUnitValueFrequencies = extractDataSouceColumnValueFrequencies(dataSource, dataSource.getSubnationalUnitColumnName(), true);
			
			// set values and valueFrequencies
			
			dataSource.setSubnationalUnitValueFrequencies(subnationalUnitValueFrequencies);
			
		}
		
		// metrics
		
		for (Metric metric : selectedPpa.getMetrics())
		{
			// selected metrics only
			
			if (metric.getSelected())
			{
				if (StringUtils.isNotEmpty(metric.getDataSourceColumnName()))
				{
					// check dataSourceColumnName is from this dataSource
					
					if (ArrayUtils.indexOf(metric.getDataSource().getUserFile().getColumnNames(), metric.getDataSourceColumnName()) == ArrayUtils.INDEX_NOT_FOUND)
						continue;
					
					// store current selection
					
					String[] selectedColumnValues = metric.getSelectedColumnValues();
					
					// refresh column valuse
					
					setMetricDataSourceColumnName(metric.getId(), metric.getDataSourceColumnName());
					
					// restore selectedColumnValues
					
					metric.setSelectedColumnValues(selectedColumnValues);
					
				}
				
			}
			
		}
		
	}
	
	/**
	 * Deletes userFile content.
	 * 
	 * @param userFile
	 */
	private void deleteUserFileContent(UserFile userFile)
	{
		int columnCount = userFile.getColumnNames().length;
		int sectionCount = getColumnSectionIndex(columnCount - 1) + 1;
		
		for (int sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++)
		{
			String tableName = getFileTableName(userFile.getId().longValue(), sectionIndex);
			
			jdbcTemplate.execute(String.format("DROP TABLE IF EXISTS \"%s\"", tableName));
			
		}
		
	}
	
	/**
	 * Builds content table name for given column name.
	 * 
	 * @param userFile
	 * @param columnName
	 */
	private String getColumnTableName(UserFile userFile, String columnName)
	{
		// get column names
		
		String[] columnNames = userFile.getColumnNames();
		
		// get column index
		
		int columnIndex = ArrayUtils.indexOf(columnNames, columnName);
		
		if (columnIndex == ArrayUtils.INDEX_NOT_FOUND)
		{
			throw new ApplicationException("Cannot find given column in available file columns. Please delete and reload file.");
			
		}
		
		// get section index
		
		int sectionIndex = getColumnSectionIndex(columnIndex);
		
		// build file name
		
		String fileName = getFileTableName(userFile.getId().longValue(), sectionIndex);
		
		return fileName;
		
	}
	
	private User getAccountActiveAdmininstrator
	(
			Account account,
			User user
	)
	{
		User accountActiveAdministrator = null;
		
		for (User accountLoggedAdministrator : userRepository.getPpaOtherLoggedAdministrators(user))
		{
			// check logged duration
			
			if (new Duration(accountLoggedAdministrator.getLastActivity(), DateTime.now(DateTimeZone.UTC)).getStandardSeconds() < sessionTimeout)
			{
				accountActiveAdministrator = accountLoggedAdministrator;
				
				break;
				
			}
			
		}
		
		return accountActiveAdministrator;
		
	}
	
	private Invitation getTokenInvitation(String token)
	{
		Invitation invitation;
		
		try
		{
			invitation = invitationRepository.findByToken(token);
			
			if (new Duration(invitation.getCreated(), DateTime.now()).getStandardSeconds() > tokenTimeoutSeconds)
			{
				throw new ApplicationException(getMessageText("acceptInvitation.expiredInvitation.message", new String[] {}));
				
			}
			
		}
		catch (EntityNotFoundException e)
		{
			throw new ApplicationException(getMessageText("acceptInvitation.invalidInvitation.message", new String[] {}));
			
		}
		
		return invitation;
		
		
	}
	
	private <T> List<T> getPage(Set<T> objects, int pageSize, int pageNumber)
	{
		int pageIndex = pageNumber - 1;
		
		int fromIndex = Math.min(objects.size(), Math.max(0, pageSize * pageIndex));
		int toIndex = Math.min(objects.size(), Math.max(fromIndex, pageSize * (pageIndex + 1)));
		
		return new ArrayList<>(objects).subList(fromIndex, toIndex);
		
	}
	
	/**
	 * Returns table rows.
	 * 
	 * @param objects
	 * @return
	 */
	private Map<String, Object> getTable(List<Map<String, Object>> objects)
	{
		Map<String, Object> tablePage = new HashMap<>();
		
		tablePage.put("total", objects.size());
		
		tablePage.put("rows", objects);
		
		return tablePage;
		
	}
	
	/**
	 * Checks whether all PpaSectorLevels are mapped for given DataSource.
	 * 
	 * @param dataSource
	 * @return
	 */
	private boolean isDataSourceAllPpaSectorLevelsMapped
	(
			DataSource dataSource
	)
	{
		// check if all aggregation levels are mapped
		
		Set<String> mappedValueCombinations = new HashSet<>();
		for (PpaSectorMapping ppaSectorMapping : dataSource.getPpaSectorMappings())
		{
			mappedValueCombinations.add(ppaSectorMapping.getValueCombination());
			
		}
		
		// return value
		
		boolean allDataSourcePpaSectorLevelsMapped = mappedValueCombinations.containsAll(dataSource.getPpaSectorMappingValueCombinationFrequencies().keySet());
		
		// build and return output
		
		return allDataSourcePpaSectorLevelsMapped;
		
	}
	
	/**
	 * Checks whether all AggregationLevels are mapped for given DataSource.
	 * 
	 * @param dataSource
	 * @return
	 */
	private boolean isDataSourceAllAggregationLevelsMapped
	(
			DataSource dataSource
	)
	{
		// check if all aggregation levels are mapped
		
		Set<String> mappedSubnationalUnits = new HashSet<>();
		for (SubnationalUnitMapping subnationalUnitMapping : dataSource.getSubnationalUnitMappings())
		{
			mappedSubnationalUnits.add(subnationalUnitMapping.getRegionColumnValue());
			
		}
		
		// return value
		
		boolean allDataSourceAggregationLevelsMapped = mappedSubnationalUnits.containsAll(dataSource.getSubnationalUnitValueFrequencies().keySet());
		
		// build and return output
		
		return allDataSourceAggregationLevelsMapped;
		
	}
	
	private int getDataSourceRowCount
	(
			DataSource dataSource
	)
	{
		String userFileTableName = getFileTableName(dataSource.getUserFile().getId(), 0);
		
		Number dataSourceRowCount =
				jdbcTemplate.queryForObject
				(
						String.format("SELECT COUNT(*) FROM \"%s\"", userFileTableName),
						Integer.class
				)
		;
		
		return dataSourceRowCount.intValue();
		
	}

	/**
	 * Prepares dataSourceSubsetCounts for table update
	 * 
	 * @param dataSourceId
	 * @return
	 */
	private Map<String, Object> getDataSourceSubsetCounts
	(
			DataSource dataSource
	)
	{
		Map<String, Object> output = new HashMap<>();
		
		// subset columns
		
		String subsetColumn1Name = dataSource.getSubsetColumn1Name();
		
		if (StringUtils.isEmpty(subsetColumn1Name))
		{
			output.put("subsetColumn1Name", "");
			output.put("subsetColumn1ValueCount", "");
			
		}
		else
		{
			output.put("subsetColumn1Name", subsetColumn1Name);
			output.put("subsetColumn1ValueCount", String.format("%d / %d", dataSource.getSubsetColumn1SelectedValues().length, dataSource.getSubsetColumn1ValueFrequencies().size()));
			
		}
		
		String subsetColumn2Name = dataSource.getSubsetColumn2Name();
		
		if (StringUtils.isEmpty(subsetColumn2Name))
		{
			output.put("subsetColumn2Name", "");
			output.put("subsetColumn2ValueCount", "");
			
		}
		else
		{
			output.put("subsetColumn2Name", subsetColumn2Name);
			output.put("subsetColumn2ValueCount", String.format("%d / %d", dataSource.getSubsetColumn2SelectedValues().length, dataSource.getSubsetColumn2ValueFrequencies().size()));
			
		}
		
		// N Rows
		
		String nRowString;
		
		if (StringUtils.isEmpty(subsetColumn1Name) && StringUtils.isEmpty(subsetColumn2Name))
		{
			nRowString = String.format("[All] %d", getDataSourceRowCount(dataSource));
			
		}
		else
		{
			String testColumnName = (StringUtils.isNotEmpty(subsetColumn1Name) ? subsetColumn1Name : subsetColumn2Name);
			
			Map<String, Long> testColumnNameValueFrequencies = extractDataSouceColumnValueFrequencies(dataSource, testColumnName, true);
			
			int nRows = 0;
			
			for (Long testColumnNameValueFrequency : testColumnNameValueFrequencies.values())
			{
				nRows += testColumnNameValueFrequency.intValue();
				
			}
			
			nRowString = String.valueOf(nRows);
			
		}
		
		output.put("nRows", nRowString);
		
		return output;
		
	}

	// ====================================================================================================
	// accessors
	// ====================================================================================================

	/**
	 * Gets messages.
	 * 
	 * @return
	 * @throws IOException 
	 */
	@RequestMapping(value = "/getMessages")
	@PreAuthorize("permitAll()")
	@ResponseBody
	public Properties getMessages
	(
	) throws IOException
	{
		// get inputStream
		
		InputStream messagesPropertiesInputStream = getClass().getClassLoader().getResourceAsStream(messagesPropertiesPath);
		
		// read messages
		
		Properties messagesProperties = new Properties();
		
		messagesProperties.load(messagesPropertiesInputStream);
		
		// return messages
		
		return messagesProperties;

	}
	
	/**
	 * Gets message for code and parameters.
	 * 
	 * @param code
	 * @param parameters
	 * @param locale
	 * @return
	 */
	@RequestMapping(value = "/getMessage")
	@PreAuthorize("permitAll()")
	@ResponseBody
	public Map<String, Object> getMessage
	(
			@RequestParam(value = "code", required = true) String code,
			@RequestParam(value = "parameters[]", required = false) String[] parameters
	)
	{
		return ImmutableMap.of("message", getMessageText(code, parameters));

	}
	
	@RequestMapping(value = "/getCurrentUser")
	@ResponseBody
	public Map<String, Object> getCurrentUser()
	{
		// get user
		
		User user = getUser();
		
		// get selectedAccount
		
		Account selectedAccount = user.getSelectedAccount();
		
		// build response
		
		Map<String, Object> response = new HashMap<>();
		
		response.put("email", user.getEmail());
		response.put("username", user.getUsername());
		response.put("enabled", user.getEnabled());
		response.put("recentLogin", user.getRecentLogin());
		response.put("navigationPage", user.getNavigationPage());
		
		// user roles
		
		List<String> roles = new ArrayList<>();
		response.put("roles", roles);
		
		roles.add(ROLE_USER);
		
		// default account values
		
		response.put("selectedAccountId", null);
		response.put("selectedAccountName", null);
		response.put("selectedAccountAdministrator", false);
		response.put("administrator", false);
		response.put("selectedPpaId", null);
		response.put("selectedPpaAggregationLevelName", null);
		
		// selectedAccount
		
		if (selectedAccount != null)
		{
			response.put("selectedAccountId", selectedAccount.getId());
			response.put("selectedAccountName", selectedAccount.getName());
			
			// get selectedAccountUserAssociation
			
			AccountUserAssociation selectedAccountUserAssociation = getAccountUserAssociation(selectedAccount, user);
			
			if (selectedAccountUserAssociation != null)
			{
				// account administrator
				
				boolean selectedAccountAdministrator = selectedAccountUserAssociation.getAdministrator();
				
				response.put("selectedAccountAdministrator", selectedAccountAdministrator);
				
				// activeAdministrator
				
				User activeAdministrator = getAccountActiveAdmininstrator(selectedAccount, user);
				response.put("administrator", selectedAccountAdministrator && (activeAdministrator == null));
				
				if (activeAdministrator == null)
				{
					if (selectedAccountAdministrator)
					{
						roles.add(ROLE_ADMIN);
						
					}
					
				}
				else
				{
					// set activeAdministratorUsername
					
					response.put("activeAdministratorUsername", activeAdministrator.getUsername());
					
				}
				
				// get selectedPpa
				
				Ppa selectedPpa = selectedAccountUserAssociation.getSelectedPpa();
				
				if (selectedPpa != null)
				{
					response.put("selectedPpaId", selectedPpa.getId());
					response.put("selectedPpaAggregationLevelName", selectedPpa.getAggregationLevel());
					
				}
				
			}
			
		}
		
	    return response;
		
	}
	
	@RequestMapping(value = "/getPpaAggregationLevel")
	@ResponseBody
	public Map<String, Object> getPpaAggregationLevel()
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(false);
		
		// populate output
		
		return ImmutableMap.of("national", (selectedPpa == null ? false : PPA_AGGREGATION_LEVEL_NATIONAL.equals(selectedPpa.getAggregationLevel())));
		
	}

	@RequestMapping(value = "/getAccountUsers")
	@ResponseBody
	public Map<String, Object> getAccountUsers
	(
			@RequestParam(value = "accountId", required = false) Long accountId,
			@RequestParam(value = "page") int pageNumber,
			@RequestParam(value = "rows") int pageSize
	)
	{
		// skip empty request
		
		if (accountId == null)
		{
			return ImmutableMap.of("total", Integer.valueOf(0), "rows", new ArrayList<>());
			
		}
		
		// get user
		
		User user = getUser();
		
		// get account
		
		Account account = accountRepository.getOne(accountId);
		
		// administration access
		
		assertAccountAdministrator(account);
		
		// get self accountUserAssociation
		
		AccountUserAssociation accountUserAssociation = accountUserAssociationRepository.findByAccountAndUser(account, user);
		
		// get other accountUserAssociations
		
		Set<AccountUserAssociation> otherAccountUserAssociations = account.getAccountUserAssociations();
		otherAccountUserAssociations.remove(accountUserAssociation);
		
		// build response
		
		Map<String, Object> response = new HashMap<>();
		
		response.put("total", otherAccountUserAssociations.size());
		
		List<Map<String, Object>> rows = new ArrayList<>();
		response.put("rows", rows);
		
		for (AccountUserAssociation otherAccountUserAssociation : getPage(otherAccountUserAssociations, pageSize, pageNumber))
		{
			User otherAccountUser = otherAccountUserAssociation.getUser();
			
			boolean otherAccountUserOwner = otherAccountUserAssociation.getOwner();
			boolean otherAccountUserAdministrator = otherAccountUserAssociation.getAdministrator();
			
			// build responseElement
			
			Map<String, Object> row = new HashMap<>();
			rows.add(row);
			
			row.put("id", otherAccountUser.getId());
			row.put("username", otherAccountUser.getUsername());
			row.put("owner", otherAccountUserOwner);
			row.put("administrator", otherAccountUserAdministrator);
			row.put("guest", isGuestUser(otherAccountUser));
			
			// can expel non-owner and non-guest only
			// can expel from non-demo account only
			
			row.put("expel", !otherAccountUserOwner && !account.getDemo() && !isGuestUser(otherAccountUser));
			
		}
		
	    return response;
		
	}

	@RequestMapping(value = "/clearCurrentUserRecentLogin")
	@Transactional
	public void clearCurrentUserRecentLogin()
	{
		// get user
		
		User user = getUser();
		
		// update user
		
		user.setRecentLogin(null);
		
	}
	
	/**
	 * Sets current navigation page in application.
	 * 
	 * @param navigationPage
	 */
	@RequestMapping(value = "/setNavigationPage")
	@org.springframework.transaction.annotation.Transactional
	public void setNavigationPage
	(
			@RequestParam(value = "navigationPage") String navigationPage
	)
	{
		User user = getUser();
		
		// set navigationPage
		
		user.setRemoteAddress(new DateTime().toString());
		user.setNavigationPage(navigationPage);
		
		System.out.println("navigationPage=" + navigationPage);
		
	}
	
	/**
	 * Creates user.
	 * 
	 * @param username
	 * @param password
	 * @param enabled
	 * @param administrator
	 */
	private User createUser
	(
			String username,
			String password,
			boolean emailConfirmed
	)
	{
		// Force Failure!
		if (username.startsWith("forcefailure")) 
		{
			throw new ApplicationException("Forced failure!");
		}

		// check user is registered

		User user = userRepository.findByUsername(username);
		
		if (user == null)
		{
			// create user
			user = new User();

			user.setEmail(username);
			user.setUsername(username);
			user.setEnabled(emailConfirmed);
			
			// set user role
			
			UserRole userUserRole = new UserRole();
			user.addUserRole(userUserRole);
			
			userUserRole.setRole(ROLE_USER);
			
			// password
			
			user.setPassword(passwordEncoder.encode(password));
			
			// save

			userRepository.save(user);

			// associate this user with all demo accounts
			
			for (Account demoAccount : accountRepository.findAllByDemo(true))
			{
				// skip accounts already assiciated with this user
				
				AccountUserAssociation demoAccountExistingAccountUserAssociation = accountUserAssociationRepository.findByAccountAndUser(demoAccount, user);
				
				if (demoAccountExistingAccountUserAssociation != null)
					continue;
				
				// create accountUserAssociation
				
				AccountUserAssociation demoAccountNewAccountUserAssociation = new AccountUserAssociation();
				demoAccount.addAccountUserAssociation(user, demoAccountNewAccountUserAssociation);
				
			}
		}
		else
		{
			// check user is validated
			
			if (user.getEnabled())
			{
				throw new ApplicationException(getMessageText("common.uniqueUsernameValidationError.text", new String[] {}));
				
			}
			else
			{
				// update password
				
				user.setPassword(passwordEncoder.encode(password));

			}
			
		}
		
		// return user
		
		return user;
		
	}
	
	/**
	 * Administrator's method to invite user. Allows create administrators.
	 * 
	 * @param email
	 * @param administrator
	 */
	@RequestMapping(value = "/inviteUser")
	@Transactional
	public void inviteUser
	(
			@RequestParam(value = "accountId") Long accountId,
			@RequestParam(value = "email") String email,
			HttpServletRequest httpServletRequest
	)
	{
		// get account
		
		Account account = accountRepository.getOne(accountId);
		
		// assert administration access
		
		assertAccountAdministrator(account);
		
		// check user exists
		
		if (userRepository.existsByUsername(email))
		{
			User user = userRepository.findByUsername(email);
			
			// check user associated to account
			
			if (accountUserAssociationRepository.existsByAccountAndUser(account, user))
			{
				throw new ApplicationException("User with this email is already member of this account.");
				
			}
			
		}
		
		// create token
		
		String token = UUID.randomUUID().toString();
		
		// create invitation
		
		Invitation invitation = new Invitation();
		account.addInvitation(invitation);
		
		invitation.setEmail(email);
		invitation.setToken(token);
		
		// build registrationUrl
		
		String registrationUrl =
				String.format
				(
						"%s://%s:%d/%s?%s&%s=%s",
						httpServletRequest.getScheme(),
						httpServletRequest.getServerName(),
						httpServletRequest.getServerPort(),
						homePath,
						acceptInvitationKey,
						tokenKey,
						token
				)
		;
		
		// send invitation email
		
		sendInvitationEmail(email, account.getName(), registrationUrl);
		
	}
	
	/**
	 * Administrator's method to expel user.
	 * 
	 * @param userIds
	 */
	@RequestMapping(value = "/expelAccountUser")
	@ResponseBody
	@Transactional
	public void expelAccountUser
	(
			@RequestParam(value = "accountId") Long accountId,
			@RequestParam(value = "userId") Long userId
	)
	{
		// get account
		
		Account account = accountRepository.getOne(accountId);
		
		// assert administration access
		
		assertAccountAdministrator(account);
		
		// get user
		
		User user = getUser();
		
		// check self operation
		
		if (user.getId().equals(userId))
		{
			throw new ApplicationException("You cannot expel yourself.");
			
		}
		
		// get accountUser
		
		User accountUser = userRepository.getOne(userId);

		assertNotGuestUser(accountUser);
		
		// get accountUserAssociation
		
		AccountUserAssociation accountUserAssociation = accountUserAssociationRepository.findByAccountAndUser(account, accountUser);
		
		// remvoe association
		
		account.removeAccountUserAssociation(accountUserAssociation);
		
	}

	@RequestMapping(value = "/checkAccountNameExists")
	@PreAuthorize("permitAll()")
	@ResponseBody
	public Map<String, Object> checkAccountNameExists
	(
			@RequestParam(value = "name") String name
	)
	{
		// build response
		
		return ImmutableMap.of("accountNameExists", accountRepository.existsByName(name));
		
	}
	
	/**
	 * Checks if username is registered.
	 *  
	 * @param username
	 * @return
	 */
	@RequestMapping(value = "/checkUsernameExists")
	@PreAuthorize("permitAll()")
	@ResponseBody
	public Map<String, Object> checkUsernameExists
	(
			@RequestParam(value = "username") String username
	)
	{
		// check username
		
		List<User> users = userRepository.findAllByUsername(username);
		
		// build output
		
		return ImmutableMap.of("usernameExists", users.size() != 0);
		
	}
	
	/**
	 * Checks if username is registered and validated.
	 * 
	 * @param username
	 * @return
	 */
	@RequestMapping(value = "/checkUsernameValidated")
	@PreAuthorize("permitAll()")
	@ResponseBody
	public Map<String, Object> checkUsernameValidated
	(
			@RequestParam(value = "username") String username
	)
	{
		// check username
		
		User user = userRepository.findByUsername(username);
		
		// build output
		
		return ImmutableMap.of("usernameValidated", user != null && user.getEnabled());
		
	}
	
	/**
	 * User self-registration method.
	 * 
	 * @param username
	 * @param password
	 * @param email
	 * @param name
	 */
	@RequestMapping(value = "/registerUser")
	@PreAuthorize("permitAll()")
	@Transactional
	@ResponseBody
	public void registerUser
	(
			@RequestParam(value = "username") String username,
			@RequestParam(value = "password") String password
	)
	{
		// In local/offline mode we create an enabled user immediately and do not
		// rely on confirmation emails.
		if (localMode)
		{
			createUser(username, password, true);
			return;
		}

		// Hosted / cloud behavior: create user then send confirmation email
		User user = createUser(username, password, false);
		sendConfirmationEmail(user);
	}

	/**
	 * Programmatic guest login for local/desktop mode.
	 * Creates the guest user and Public account on first use, then
	 * authenticates the current session as the guest user.
	 */
	@RequestMapping(value = "/guestLogin")
	@PreAuthorize("permitAll()")
	@Transactional
	public void guestLogin(HttpServletRequest request)
	{
		if (!localMode)
		{
			throw new ApplicationException("Guest login is only available in local/desktop mode.");
		}

		User guestUser = userRepository.findByUsername(GUEST_USERNAME);

		if (guestUser == null)
		{
			Account publicAccount = accountRepository.findByName("Public");

			if (publicAccount == null)
			{
				publicAccount = new Account();
				publicAccount.setName("Public");
				publicAccount.setDemo(false);
				accountRepository.save(publicAccount);
			}

			guestUser = new User();
			guestUser.setUsername(GUEST_USERNAME);
			guestUser.setEmail(GUEST_USERNAME);
			guestUser.setName("Guest");
			guestUser.setPassword(passwordEncoder.encode(UUID.randomUUID().toString()));
			guestUser.setEnabled(true);
			guestUser.setSelectedAccount(publicAccount);

			UserRole userRole = new UserRole();
			guestUser.addUserRole(userRole);
			userRole.setRole(ROLE_USER);

			userRepository.save(guestUser);

			AccountUserAssociation association = new AccountUserAssociation();
			publicAccount.addAccountUserAssociation(guestUser, association);
		}

		Set<GrantedAuthority> authorities = new HashSet<>();
		for (UserRole userRole : guestUser.getUserRoles())
		{
			authorities.add(new SimpleGrantedAuthority(userRole.getRole()));
		}

		UsernamePasswordAuthenticationToken authToken =
				new UsernamePasswordAuthenticationToken(
						new MyUserDetails(guestUser.getUsername(), guestUser.getPassword(), authorities),
						null,
						authorities
				);

		SecurityContextHolder.getContext().setAuthentication(authToken);
		request.getSession(true);

		guestUser.setLogged(true);
	}

	/**
	 * Accepts user invitation.
	 * 
	 * @param username
	 * @param password
	 * @param email
	 * @param name
	 */
	@RequestMapping(value = "/acceptInvitation")
	@PreAuthorize("permitAll()")
	@Transactional
	@ResponseBody
	public Map<String, Object> acceptInvitation
	(
			@RequestParam(value = "token") String token,
			@RequestParam(value = "password", required = false) String password
	)
	{
		// get invitation by token
		
		Invitation invitation = getTokenInvitation(token);
		
		// get user
		
		User user;
		
		if (userRepository.existsByUsername(invitation.getEmail()))
		{
			// get user
			
			user = userRepository.findByUsername(invitation.getEmail());
			
		}
		else
		{
			// password should be provided for new user
			
			if (password == null)
			{
				throw new ApplicationException("Password is not provided for new user.");
			}
			
			// create user
			
			user = createUser(invitation.getEmail(), password, true);
			
		}
		
		// assign user to account
		
		AccountUserAssociation accountUserAssociation = new AccountUserAssociation();
		invitation.getAccount().addAccountUserAssociation(user, accountUserAssociation);
		
		// delete invitation
		
		invitationRepository.delete(invitation);
		
		// NWL email the admins that an invitation was accepted:
		Set<AccountUserAssociation> accountUserAssociations = invitation.getAccount().getAccountUserAssociations();
		for (AccountUserAssociation association : accountUserAssociations)
		{
			// Only send mail to the admins
			if(association.getAdministrator()==false)
				continue;
			String acceptee = user.getEmail();
			String recipient = association.getUser().getEmail();
			String space=invitation.getAccount().getName();
			String subject = getMessageText("email.invitation.accepted.subject", new String[] {acceptee, space});
			String message = getMessageText("email.invitation.accepted.message", new String[] {acceptee, space});
			sendEmail(recipient, subject, message);
		}
		
		// return user name
		
		return ImmutableMap.of("username", user.getUsername());
		
	}
	
	/**
	 * User self-update method.
	 * 
	 * @param username
	 * @param password
	 * @param email
	 * @param name
	 */
	@RequestMapping(value = "/updateUser")
	@Transactional
	@ResponseBody
	public void updateUser
	(
			@RequestParam(value = "username", required = false) String username,
			@RequestParam(value = "password", required = false) String password
	)
	{
		User user = getUser();

		assertNotGuestUser(user);
		
		if (StringUtils.isNotEmpty(username))
		{
			// check username is unique
			
			List<User> existingUsers = userRepository.findAllByUsername(username);
			
			existingUsers.remove(user);
			
			if (existingUsers.size() >= 1)
			{
				throw new ApplicationException("The email is already registered. Login with this email or reset password if you forgot it.");
				
			}
			
			// set username and email
			
			user.setUsername(username);
			user.setEmail(username);
			
			// disable user
			
			user.setEnabled(false);
			
			// send confirmation email
			
			sendConfirmationEmail(user);
			
			// invalidate authentication
			
			SecurityContextHolder.clearContext();
			
		}
		
		if (StringUtils.isNotEmpty(password))
		{
			user.setPassword(passwordEncoder.encode(password));
			
		}
		
	}
	
	@RequestMapping(value = "/setUserEmail")
	@ResponseBody
	@Transactional
	public void setUserEmail
	(
			@RequestParam(value = "userId") Long userId,
			@RequestParam(value = "email") String email
	)
	{
		User user = userRepository.getOne(userId);

		assertNotGuestUser(user);

		user.setEmail(email);

	}

	@RequestMapping(value = "/setUserUsername")
	@ResponseBody
	@Transactional
	public void setUserUsername
	(
			@RequestParam(value = "userId") Long userId,
			@RequestParam(value = "username") String username
	)
	{
		User user = userRepository.getOne(userId);

		assertNotGuestUser(user);

		user.setUsername(username);
		user.setEmail(username);

	}

	@RequestMapping(value = "/setUsername")
	@ResponseBody
	@Transactional
	public void setUsername
	(
			@RequestParam(value = "username") String username
	)
	{
		User user = getUser();

		assertNotGuestUser(user);

		user.setUsername(username);
		user.setEmail(username);

	}

	@RequestMapping(value = "/setPassword")
	@ResponseBody
	@Transactional
	public void setPassword
	(
			@RequestParam(value = "password") String password
	)
	{
		User user = getUser();

		assertNotGuestUser(user);

		user.setPassword(passwordEncoder.encode(password));

	}

	@RequestMapping(value = "/setUserEnabled")
	@ResponseBody
	@Transactional
	public void setUserEnabled
	(
			@RequestParam(value = "userId") Long userId,
			@RequestParam(value = "enabled") Boolean enabled
	)
	{
		User user = userRepository.getOne(userId);

		assertNotGuestUser(user);

		user.setEnabled(enabled);

	}

	@RequestMapping(value = "/setAccountUserAdministrator")
	@ResponseBody
	@Transactional
	public void setAccountUserAdministrator
	(
			@RequestParam(value = "accountId") Long accountId,
			@RequestParam(value = "userId") Long userId,
			@RequestParam(value = "administrator") boolean administrator
	)
	{
		// get account

		Account account = accountRepository.getOne(accountId);

		// get user

		User user = userRepository.getOne(userId);

		assertNotGuestUser(user);

		// get accountUserAssociation

		AccountUserAssociation accountUserAssociation = getAccountUserAssociation(account, user);
		
		// set administrator
		
		accountUserAssociation.setAdministrator(administrator);
		
	}
	
	@RequestMapping(value = "/sendRecoverUsernameAndPasswordLink")
	@ResponseBody
	@PreAuthorize("permitAll()")
	@Transactional
	public void sendRecoverUsernameAndPasswordLink
	(
			@RequestParam(value = "email") String email
	)
	{
		User user = userRepository.findByUsername(email);
		
		// email is not registered
		
		if (user == null)
		{
			throw new ApplicationException("This email is not registered. Please use an email that you used for registration.");
			
		}
		
		setResetPasswordTokenAndSendEmail(user);

	}

	@RequestMapping(value = "/sendResetPasswordLink")
	@ResponseBody
	@Transactional
	public void sendResetPasswordLink
	(
	)
	{
		User user = getUser();
		
		setResetPasswordTokenAndSendEmail(user);

	}

	/**
	 * User invitation registration method.
	 * 
	 * @param token
	 * @param username
	 * @param password
	 */
	@RequestMapping(value = "/resetPassword")
	@PreAuthorize("permitAll()")
	@Transactional
	@ResponseBody
	public void resetPassword
	(
			@RequestParam(value = "token") String token,
			@RequestParam(value = "password") String password
	)
	{
		// check token
		
		if (!((Boolean)getResetPasswordTokenVerification(token).get("success")).booleanValue())
		{
			throw new ApplicationException("Invalid token.");
			
		}
		
		// get user
		
		List<User> users = userRepository.findByResetPasswordToken(token);
		
		if (users.size() != 1)
		{
			throw new ApplicationException("Invalid token.");
			
		}
		
		User user = users.get(0);
		
		// set password
		
		user.setPassword(passwordEncoder.encode(password));
		
		// clear token
		
		user.setResetPasswordToken(null);
		user.setResetPasswordTokenCreated(null);
		
	}
	
	@RequestMapping(value = "/getUserFiles")
	@ResponseBody
	public List<Map<String, Object>> getUserFiles
	(
	)
	{
		// get user
		
		User user = getUser();
		
		// get selectedAccount
		
		Account selectedAccount = user.getSelectedAccount();
		
		// check selectedAccount is not empty
		
		if (selectedAccount == null)
		{
			throw new ApplicationException("Cannot list Data Sources without selected account.");
			
		}
		
		// get account administrator
		
		boolean selectedAccountAdministrator = isUserAccountAdministrator(selectedAccount, user);
		
		// populate output
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (UserFile userFile : user.getSelectedAccount().getUserFiles())
		{
			Map<String, Object> outputRow = new HashMap<>();
			output.add(outputRow);
			
			outputRow.put("id", userFile.getId());
			outputRow.put("fileName", userFile.getFileName());
			outputRow.put("delete", selectedAccountAdministrator);
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/getUserFileDependentPpaNames")
	@ResponseBody
	public List<String> getUserFileDependentPpaNames
	(
			@RequestParam(value = "userFileId") Long userFileId
	)
	{
		// get userFile
		
		UserFile userFile = userFileRepository.getOne(userFileId);
		
		// populate dependent PPA if dataSource can be deleted
		
		List<String> dependentPpaNames = new ArrayList<>();
		
		for (DataSource dataSource : userFile.getDataSources())
		{
			Ppa ppa = dataSource.getPpa();
			
			dependentPpaNames.add(ppa.getName());
			
		}
		
		return dependentPpaNames;
		
	}

	@RequestMapping(value = "/getUserFilesUsed")
	@ResponseBody
	public Map<String, Object> getUserFilesUsed
	(
			@RequestParam(value = "userFileIds[]") Set<Long> userFileIds
	)
	{
		// get userFiles
		
		Set<UserFile> userFiles = userFileRepository.findByIdIn(userFileIds);
		
		// find if anyone of these files is used
		
		boolean used = false;
		
		userFiles:
		for (UserFile userFile : userFiles)
		{
			for (DataSource dataSource : userFile.getDataSources())
			{
				if (dataSource.getMetrics().size() >= 1)
				{
					used = true;
					break userFiles;
					
				}
				
			}
			
		}
		
		// populate output
		
		return ImmutableMap.of("used", used);
		
	}

	@RequestMapping(value = "/getAccounts")
	@ResponseBody
	public List<Map<String, Object>> getAccounts
	(
	)
	{
		// get user
		
		User user = getUser();
		
		// get selectedAccount
		
		Account selectedAccount = user.getSelectedAccount();
		
		// build response
		
		List<Map<String, Object>> response = new ArrayList<>();
		
		for (AccountUserAssociation accountUserAssociation : user.getAccountUserAssociations())
		{
			Account account = accountUserAssociation.getAccount();
			
			boolean owner = accountUserAssociation.getOwner();
			boolean administrator = accountUserAssociation.getAdministrator();
			
			Map<String, Object> responseElement = new HashMap<>();
			response.add(responseElement);
			
			responseElement.put("id", account.getId());
			responseElement.put("name", account.getName());
			responseElement.put("owner", owner);
			responseElement.put("administrator", administrator);
			responseElement.put("manage", administrator);
			responseElement.put("delete", owner);
			
			// can leave if not owner only
			// can leave if not demo account only
			
			responseElement.put("leave", !owner && !account.getDemo());
			
			if (account == selectedAccount)
			{
				responseElement.put("selected", true);
				
			}
			
		}
		
		return response;

	}

	@RequestMapping(value = "/getAccountsTable")
	@ResponseBody
	public Map<String, Object> getAccountsTable
	(
//			@RequestParam(value = "sort") String sortColumn,
//			@RequestParam(value = "order") String sortOrder,
//			@RequestParam(value = "rows") int pageSize,
//			@RequestParam(value = "page") int pageNumber
	)
	{
		return getTable(getAccounts());

	}

	@RequestMapping(value = "/getAccount")
	@ResponseBody
	public Map<String, Object> getAccount
	(
			@RequestParam(value = "accountId") Long accountId
	)
	{
		// get account
		
		Account account = accountRepository.getOne(accountId);
		
		// build response
		
		Map<String, Object> response = new HashMap<>();
		
		response.put("id", account.getId());
		response.put("name", account.getName());
		
		return response;

	}

	@RequestMapping(value = "/createAccount")
	@Transactional
	public void createAccount
	(
			@RequestParam(value = "name") String name,
			@RequestParam(value = "demo") boolean demo
	)
	{
		// check accountName unique
		
		if (accountRepository.existsByName(name))
		{
			throw new ApplicationException(getMessageText("Accounts.createAccount.uniqueAccountNameValidationError.text", new String[] {}));
			
		}
		
		// create account
		
		Account account = new Account();
		account.setName(name);
		account.setDemo(demo);
		
		// save account
		
		accountRepository.save(account);
		accountRepository.flush();
		accountRepository.refresh(account);
		
		// get user
		
		User user = getUser();
		
		// create accountUserAssociation
		
		AccountUserAssociation accountUserAssociation = new AccountUserAssociation();
		accountUserAssociation.setOwner(true);
		accountUserAssociation.setAdministrator(true);
		
		// link user and account
		
		account.addAccountUserAssociation(user, accountUserAssociation);
		
		// link demo account to all users
		
		if (demo)
		{
			for (User otherUser : userRepository.findAll())
			{
				// skip users already assiciated with this account
				
				AccountUserAssociation otherUserExistingAccountUserAssociation = accountUserAssociationRepository.findByAccountAndUser(account, otherUser);
				
				if (otherUserExistingAccountUserAssociation != null)
					continue;
				
				// create accountUserAssociation
				
				AccountUserAssociation otherUserNewAccountUserAssociation = new AccountUserAssociation();
				account.addAccountUserAssociation(otherUser, otherUserNewAccountUserAssociation);
				
			}
			
		}
		
	}
	
	@RequestMapping(value = "/deleteAccount")
	@Transactional
	public void deleteAccount
	(
			@RequestParam(value = "accountId") Long accountId
	)
	{
		// get account
		
		Account account = accountRepository.getOne(accountId);
		
		// remove account selection if deleted
		
		List<User> users = userRepository.findAll();
		
		for (User user : users)
		{
			Account selectedAccount = user.getSelectedAccount();
			
			if (selectedAccount == account)
			{
				user.setSelectedAccount(null);
				
			}
			
		}
		
		// delete account
		
		accountRepository.delete(account);
		
	}
	
	@RequestMapping(value = "/leaveAccount")
	@Transactional
	public void leaveAccount
	(
			@RequestParam(value = "accountId") Long accountId
	)
	{
		// get user
		
		User user = getUser();
		
		// get account
		
		Account account = accountRepository.getOne(accountId);
		
		// get accountUserAssociation
		
		AccountUserAssociation accountUserAssociation = accountUserAssociationRepository.findByAccountAndUser(account, user);
		
		// delete accountUserAssociation
		
		account.removeAccountUserAssociation(accountUserAssociation);
		
	}
	
	@RequestMapping(value = "/selectAccount")
	@Transactional
	public void selectAccount
	(
			@RequestParam(value = "accountId") Long accountId
	)
	{
		Account account = accountRepository.getOne(accountId);
		
		getUser().setSelectedAccount(account);
		
	}

	@RequestMapping(value = "/getSelectedPpaId")
	@ResponseBody
	public Map<String, Object> getSelectedPpaId()
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(false);
		
		// populate output
		
		return ImmutableMap.of("selectedPpaId", (selectedPpa == null ? "" : selectedPpa.getId()));

	}

	@RequestMapping(value = "/getSelectedPpaName")
	@ResponseBody
	public Map<String, Object> getSelectedPpaName
	(
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(false);
		
		// populate output
		
		return ImmutableMap.of("ppaName", (selectedPpa == null ? "" : selectedPpa.getName()));

	}

	@RequestMapping(value = "/getPpaStatus")
	@ResponseBody
	public Map<String, Object> getPpaStatus
	(
	)
	{
		return ImmutableMap.of("ppaSet", getSelectedPpa(false) != null);

	}

	@RequestMapping(value = "/getPpas")
	@ResponseBody
	public List<Map<String, Object>> getPpas
	(
	)
	{
		User user = getUser();
		Account selectedAccount = user.getSelectedAccount();
		
		// return empty list if account is not selected
		
		if (selectedAccount == null)
		{
			return new ArrayList<>();
			
		}
		
		// get accountUserAssociation
		
		AccountUserAssociation accountUserAssociation = accountUserAssociationRepository.findByAccountAndUser(selectedAccount, user);
		
		// return empty list if accountUserAssociation is null
		
		if (accountUserAssociation == null)
		{
			return new ArrayList<>();
			
		}
		
		// get selectedPpa
		
		Ppa selectedPpa = accountUserAssociation.getSelectedPpa();
		
		// build ppas
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (Ppa ppa : user.getSelectedAccount().getPpas())
		{
			Map<String, Object> outputRow = new HashMap<>();
			output.add(outputRow);
			
			outputRow.put("id", ppa.getId());
			outputRow.put("name", ppa.getName());
			outputRow.put("region", ppa.getAggregationLevel());
			outputRow.put("duplicate", true);
			outputRow.put("delete", true);
			
			if (selectedPpa != null && ppa.getId().longValue() == selectedPpa.getId().longValue())
			{
				outputRow.put("selected", true);
				
			}
			
		}
		
		return output;

	}

	/**
	 * Exports a single PPA (configuration + referenced user files) into a
	 * passwordless .ppa archive (ZIP with meta.json, ppa.json and data/*).
	 */
	@RequestMapping(value = "/exportPpa")
	@ResponseBody
	@Transactional(readOnly = true)
	public HttpEntity<byte[]> exportPpa
	(
			@RequestParam(value = "ppaId") Long ppaId
	)
	{
		User user = getUser();
		Account account = user.getSelectedAccount();

		if (account == null)
		{
			throw new ApplicationException("Team space is not selected.");
		}

		Ppa ppa = ppaRepository.getOne(ppaId);

		if (ppa == null || ppa.getAccount() == null || !ppa.getAccount().getId().equals(account.getId()))
		{
			throw new ApplicationException("PPA not found for selected team space.");
		}

		// Build DTO graph
		PpaExportDto exportDto = new PpaExportDto();
		exportDto.originalId = ppa.getId();
		exportDto.name = ppa.getName();
		exportDto.aggregationLevel = ppa.getAggregationLevel();

		List<PpaExportDto.DataSourceDto> dataSourceDtos = new ArrayList<>();
		List<PpaExportDto.MetricDto> metricDtos = new ArrayList<>();
		List<PpaExportDto.PpaSectorDto> sectorDtos = new ArrayList<>();
		List<PpaExportDto.PpaSectorLevelDto> levelDtos = new ArrayList<>();
		List<PpaExportDto.PpaSectorMappingDto> sectorMappingDtos = new ArrayList<>();
		List<PpaExportDto.SubnationalUnitDto> subnationalUnitDtos = new ArrayList<>();
		List<PpaExportDto.SubnationalUnitMappingDto> subnationalMappingDtos = new ArrayList<>();
		List<PpaExportDto.UserFileDto> userFileDtos = new ArrayList<>();

		Map<Long, UserFile> userFilesById = new LinkedHashMap<>();

		// DataSources + collect UserFiles
		for (DataSource dataSource : ppa.getDataSources())
		{
			PpaExportDto.DataSourceDto dto = new PpaExportDto.DataSourceDto();
			dto.originalId = dataSource.getId();

			UserFile userFile = dataSource.getUserFile();
			if (userFile != null)
			{
				dto.userFileOriginalId = userFile.getId();
				userFilesById.putIfAbsent(userFile.getId(), userFile);
			}

			dto.subnationalUnitColumnName = dataSource.getSubnationalUnitColumnName();
			dto.subnationalUnitValueFrequencies = dataSource.getSubnationalUnitValueFrequencies();
			dto.subnationalUnitSelectedValues = dataSource.getSubnationalUnitSelectedValues();

			dto.facilityTypeColumnName = dataSource.getFacilityTypeColumnName();
			dto.facilityTypeValues = dataSource.getFacilityTypeValues();
			dto.facilityTypeValueFrequencies = dataSource.getFacilityTypeValueFrequencies();

			dto.healthSectorColumnName = dataSource.getHealthSectorColumnName();
			dto.healthSectorValues = dataSource.getHealthSectorValues();
			dto.healthSectorValueFrequencies = dataSource.getHealthSectorValueFrequencies();

			dto.ppaSectorMappingValueCombinationFrequencies = dataSource.getPpaSectorMappingValueCombinationFrequencies();

			dto.subsetColumn1Name = dataSource.getSubsetColumn1Name();
			dto.subsetColumn1Values = dataSource.getSubsetColumn1Values();
			dto.subsetColumn1ValueFrequencies = dataSource.getSubsetColumn1ValueFrequencies();
			dto.subsetColumn1SelectedValues = dataSource.getSubsetColumn1SelectedValues();

			dto.subsetColumn2Name = dataSource.getSubsetColumn2Name();
			dto.subsetColumn2Values = dataSource.getSubsetColumn2Values();
			dto.subsetColumn2ValueFrequencies = dataSource.getSubsetColumn2ValueFrequencies();
			dto.subsetColumn2SelectedValues = dataSource.getSubsetColumn2SelectedValues();

			dto.selectedRowCount = dataSource.getSelectedRowCount();
			dto.weightColumnName = dataSource.getWeightColumnName();
			dto.weightMultiplier = dataSource.getWeightMultiplier();

			dataSourceDtos.add(dto);
		}

		// Metrics
		for (Metric metric : ppa.getMetrics())
		{
			PpaExportDto.MetricDto dto = new PpaExportDto.MetricDto();
			dto.originalId = metric.getId();
			dto.dataSourceOriginalId = (metric.getDataSource() != null ? metric.getDataSource().getId() : null);
			dto.metricTypeId = (metric.getMetricType() != null ? metric.getMetricType().getId() : null);
			dto.selected = metric.getSelected();
			dto.dataPointName = metric.getDataPointName();
			dto.dataSourceColumnName = metric.getDataSourceColumnName();
			dto.columnValueFrequencies = metric.getColumnValueFrequencies();
			dto.selectedColumnValues = metric.getSelectedColumnValues();

			metricDtos.add(dto);
		}

		// PPA sectors + levels
		for (PpaSector ppaSector : ppa.getPpaSectors())
		{
			PpaExportDto.PpaSectorDto sectorDto = new PpaExportDto.PpaSectorDto();
			sectorDto.originalId = ppaSector.getId();
			sectorDto.position = ppaSector.getPosition();
			sectorDto.name = ppaSector.getName();
			sectorDto.editable = ppaSector.getEditable();
			sectorDto.selected = ppaSector.getSelected();
			sectorDtos.add(sectorDto);

			for (PpaSectorLevel level : ppaSector.getPpaSectorLevels())
			{
				PpaExportDto.PpaSectorLevelDto levelDto = new PpaExportDto.PpaSectorLevelDto();
				levelDto.originalId = level.getId();
				levelDto.ppaSectorOriginalId = ppaSector.getId();
				levelDto.level = level.getLevel();
				levelDtos.add(levelDto);
			}
		}

		// Sector mappings
		for (DataSource dataSource : ppa.getDataSources())
		{
			for (PpaSectorMapping mapping : dataSource.getPpaSectorMappings())
			{
				PpaExportDto.PpaSectorMappingDto dto = new PpaExportDto.PpaSectorMappingDto();
				dto.originalId = mapping.getId();
				dto.dataSourceOriginalId = dataSource.getId();
				dto.ppaSectorLevelOriginalId = mapping.getPpaSectorLevel().getId();
				dto.valueCombination = mapping.getValueCombination();
				sectorMappingDtos.add(dto);
			}
		}

		// Subnational units + mappings
		for (SubnationalUnit unit : ppa.getSubnationalUnits())
		{
			PpaExportDto.SubnationalUnitDto dto = new PpaExportDto.SubnationalUnitDto();
			dto.originalId = unit.getId();
			dto.name = unit.getName();
			subnationalUnitDtos.add(dto);

			for (SubnationalUnitMapping mapping : unit.getSubnationalUnitMappings())
			{
				PpaExportDto.SubnationalUnitMappingDto mDto = new PpaExportDto.SubnationalUnitMappingDto();
				mDto.originalId = mapping.getId();
				mDto.dataSourceOriginalId = mapping.getDataSource().getId();
				mDto.subnationalUnitOriginalId = unit.getId();
				mDto.regionColumnValue = mapping.getRegionColumnValue();
				subnationalMappingDtos.add(mDto);
			}
		}

		// User files + assign deterministic fileRef
		int fileCounter = 1;
		Map<Long, String> userFileIdToRef = new HashMap<>();
		for (UserFile userFile : userFilesById.values())
		{
			PpaExportDto.UserFileDto dto = new PpaExportDto.UserFileDto();
			dto.originalId = userFile.getId();
			dto.fileName = userFile.getFileName();

			String fileRef = String.format("data/%d-%s", fileCounter++, sanitizeFileName(userFile.getFileName()));
			dto.fileRef = fileRef;

			userFileIdToRef.put(userFile.getId(), fileRef);
			userFileDtos.add(dto);
		}

		exportDto.dataSources = dataSourceDtos;
		exportDto.metrics = metricDtos;
		exportDto.ppaSectors = sectorDtos;
		exportDto.ppaSectorLevels = levelDtos;
		exportDto.ppaSectorMappings = sectorMappingDtos;
		exportDto.subnationalUnits = subnationalUnitDtos;
		exportDto.subnationalUnitMappings = subnationalMappingDtos;
		exportDto.userFiles = userFileDtos;

		// Build ZIP
		ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
		ZipOutputStream zipOutputStream = new ZipOutputStream(byteArrayOutputStream);

		try
		{
			// meta.json
			Map<String, Object> meta = new LinkedHashMap<>();
			meta.put("schemaVersion", PPA_EXPORT_SCHEMA_VERSION);
			meta.put("exportedAt", DateTime.now(DateTimeZone.UTC).toString());

			byte[] metaBytes = objectMapper.writeValueAsBytes(meta);
			zipOutputStream.putNextEntry(new ZipEntry("meta.json"));
			zipOutputStream.write(metaBytes);

			// ppa.json
			byte[] ppaBytes = objectMapper.writeValueAsBytes(exportDto);
			zipOutputStream.putNextEntry(new ZipEntry("ppa.json"));
			zipOutputStream.write(ppaBytes);

			// data/* entries — skip files that are not available locally
			// (e.g. data sources uploaded in a cloud environment whose files
			// are not present on the local /s3 mount).
			List<String> skippedFiles = new ArrayList<>();
			for (UserFile userFile : userFilesById.values())
			{
				String fileRef = userFileIdToRef.get(userFile.getId());
				if (fileRef == null)
				{
					continue;
				}

				try
				{
					byte[] dataBytes = readBytesFromS3OrLocal(userFile.getS3FileName(), "datasource file '" + userFile.getFileName() + "'");
					zipOutputStream.putNextEntry(new ZipEntry(fileRef));
					zipOutputStream.write(dataBytes);
				}
				catch (ApplicationException e)
				{
					System.err.println("Export: skipping unavailable datasource file '"
							+ userFile.getFileName() + "' (" + userFile.getS3FileName() + "): " + e.getMessage());
					skippedFiles.add(userFile.getFileName());
				}
			}

			if (!skippedFiles.isEmpty())
			{
				System.out.println("Export completed with " + skippedFiles.size()
						+ " datasource file(s) skipped because they were not available locally: " + skippedFiles);
			}
		}
		catch (IOException e)
		{
			throw new ApplicationException("Cannot create PPA export archive.", e);
		}
		finally
		{
			try
			{
				zipOutputStream.close();
			}
			catch (IOException e)
			{
				// ignore secondary close error, main error already thrown above
			}
		}

		byte[] compressedBytes = byteArrayOutputStream.toByteArray();

		// Prepare response
		String baseName = sanitizeFileName(ppa.getName());
		String datePart = new SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
		// Use new .ppaw extension for workspace files (legacy .ppa remains importable)
		String fileName = String.format("%s_%s.ppaw", baseName, datePart);

		HttpHeaders header = new HttpHeaders();
		header.setContentType(MediaType.APPLICATION_OCTET_STREAM);
		header.set("Content-Disposition", String.format("attachment; filename=%s", fileName));
		header.setContentLength(compressedBytes.length);

		return new HttpEntity<byte[]>(compressedBytes, header);
	}

	@RequestMapping(value = "/createPpa")
	@Transactional
	@ResponseBody
	public void createPpa
	(
	)
	{
		// get user
		
		User user = getUser();
		
		// get account
		
		Account account = user.getSelectedAccount();
		
		// create ppa
		
		Ppa ppa = new Ppa();
		ppa.setName("");
		
		account.addPpa(ppa);
		
		// create default metrics
		
		createDefaultPpaMetrics(ppa);
		
		// create standard PPA sectors
		
		for (PpaSectorDefaultValue ppaSectorDefaultValue : ppaSectorDefaultValueRepository.findAllByOrderByPosition())
		{
			PpaSector ppaSector = new PpaSector();
			ppa.addPpaSector(ppaSector);
			
			ppaSector.setPosition(ppaSectorDefaultValue.getPosition());
			ppaSector.setName(ppaSectorDefaultValue.getName());
			ppaSector.setEditable(ppaSectorDefaultValue.getEditable());
			
		}
		
		// set user selected PPA for all users if this is an only PPA in account
		
		if (account.getPpas().size() == 1)
		{
			for (AccountUserAssociation accountUserAssociation : account.getAccountUserAssociations())
			{
				accountUserAssociation.setSelectedPpa(ppa);
				
			}
			
		}
		
	}
	
	@RequestMapping(value = "/deletePpas")
	@ResponseBody
	@Transactional
	public void deletePpas
	(
			@RequestParam(value = "ppaIds[]") List<Long> ppaIds
	)
	{
		// get objects
		
		List<Ppa> ppas = ppaRepository.findByIdIn(ppaIds);
		
		// update database
		
		for (Ppa ppa : ppas)
		{
			if (ppa.getAccount() != null)
			{
				Account account = ppa.getAccount();
				
				// clear selectedPpa references in account-user associations
				// to avoid FK constraint issues during cascade delete
				for (AccountUserAssociation aua : account.getAccountUserAssociations())
				{
					if (aua.getSelectedPpa() != null && aua.getSelectedPpa().getId().equals(ppa.getId()))
					{
						aua.setSelectedPpa(null);
					}
				}
				
				// clear dataSource references in metrics to avoid FK ordering
				// issues when Hibernate cascade-deletes both metrics and data sources
				for (Metric metric : ppa.getMetrics())
				{
					metric.setDataSource(null);
				}
				
				// remove from owning account (triggers orphanRemoval cascade)
				account.removePpa(ppa);
			}
		}

	}

	/**
	 * Imports a .ppa archive (ZIP with meta.json, ppa.json and data/*) and
	 * recreates a new PPA under the currently selected account.
	 */
	@RequestMapping(value = "/importPpa")
	@ResponseBody
	@Transactional
	public Map<String, Object> importPpa
	(
			@RequestParam(value = "file") MultipartFile file
	)
	{
		User user = getUser();
		Account account = user.getSelectedAccount();

		if (account == null)
		{
			throw new ApplicationException("Team space is not selected.");
		}

		byte[] metaBytes = null;
		byte[] ppaBytes = null;
		Map<String, byte[]> dataEntries = new HashMap<>();

		// Read the ZIP structure
		try (ZipInputStream zipInputStream = new ZipInputStream(file.getInputStream()))
		{
			ZipEntry entry;
			while ((entry = zipInputStream.getNextEntry()) != null)
			{
				if (entry.isDirectory())
				{
					continue;
				}

				byte[] bytes = IOUtils.toByteArray(zipInputStream);
				String name = entry.getName();

				if ("meta.json".equals(name))
				{
					metaBytes = bytes;
				}
				else if ("ppa.json".equals(name))
				{
					ppaBytes = bytes;
				}
				else if (name.startsWith("data/"))
				{
					dataEntries.put(name, bytes);
				}

				zipInputStream.closeEntry();
			}
		}
		catch (IOException e)
		{
			throw new ApplicationException("Cannot read uploaded .ppa file.", e);
		}

		if (metaBytes == null || ppaBytes == null)
		{
			throw new ApplicationException("Invalid .ppa file. Missing meta.json or ppa.json.");
		}

		// Validate meta
		try
		{
			Map<String, Object> meta = objectMapper.readValue(metaBytes, new TypeReference<Map<String, Object>>(){});
			Object schemaVersionObject = meta.get("schemaVersion");

			int schemaVersion;
			if (schemaVersionObject instanceof Number)
			{
				schemaVersion = ((Number)schemaVersionObject).intValue();
			}
			else
			{
				schemaVersion = Integer.parseInt(String.valueOf(schemaVersionObject));
			}

			if (schemaVersion != PPA_EXPORT_SCHEMA_VERSION)
			{
				throw new ApplicationException("Unsupported PPA export schema version: " + schemaVersion);
			}
		}
		catch (IOException e)
		{
			throw new ApplicationException("Cannot parse meta.json inside .ppa file.", e);
		}

		// Parse PPA export DTO
		PpaExportDto exportDto;
		try
		{
			exportDto = objectMapper.readValue(ppaBytes, PpaExportDto.class);
		}
		catch (IOException e)
		{
			throw new ApplicationException("Cannot parse ppa.json inside .ppa file.", e);
		}

		if (exportDto == null)
		{
			throw new ApplicationException("Empty PPA export payload.");
		}

		// Recreate user files using the existing upload pipeline.
		// Data files that were not available during export (e.g. cloud-only
		// datasources) are skipped so the import can still succeed.
		Map<Long, UserFile> userFileByOriginalId = new HashMap<>();
		List<String> skippedUserFiles = new ArrayList<>();
		for (PpaExportDto.UserFileDto userFileDto : exportDto.userFiles)
		{
			byte[] bytes = dataEntries.get(userFileDto.fileRef);
			if (bytes == null)
			{
				System.err.println("Import: skipping user file '"
						+ userFileDto.fileName + "' (ref=" + userFileDto.fileRef
						+ ") — data entry not present in archive.");
				skippedUserFiles.add(userFileDto.fileName != null ? userFileDto.fileName : userFileDto.fileRef);
				continue;
			}

			// Base name from export; fall back to a generic label if missing
			String originalFileName =
					(StringUtils.isNotBlank(userFileDto.fileName) ? userFileDto.fileName : "imported-data.csv");

			// First attempt: proactively choose a name that does not clash with any
			// existing user files in this account.
			String candidateFileName = generateUniqueUserFileNameForImport(account, originalFileName);

			int renameAttempts = 0;
			Long newUserFileId = null;
			while (true)
			{
				try
				{
					if (!candidateFileName.equals(originalFileName) && renameAttempts == 0)
					{
						System.out.println(String.format(
								"Auto-renaming imported user file '%s' to '%s' to avoid name collision.",
								originalFileName,
								candidateFileName));
					}

					MultipartFile inMemoryFile =
							new InMemoryMultipartFile("file", candidateFileName, "application/octet-stream", bytes);

					Map<String, Object> loadUserFileResponse = loadUserFile(inMemoryFile);
					newUserFileId = (Long)loadUserFileResponse.get("userFileId");

					if (newUserFileId == null)
					{
						throw new ApplicationException("System error. Method loadUserFile didn't return userFileId.");
					}

					// Success – break out of retry loop
					break;
				}
				catch (ApplicationException e)
				{
					String message = e.getMessage();

					// If the duplicate-name guard in loadUserFile still triggers for this
					// account (e.g. due to concurrent imports or multiple user files with
					// the same exported name), transparently retry with a fresh unique
					// name a few times instead of surfacing the error to the user.
					if (message != null
							&& message.contains("You have already loaded file with this name.")
							&& renameAttempts < 3)
					{
						renameAttempts++;
						candidateFileName = generateUniqueUserFileNameForImport(account, candidateFileName);
						System.out.println(String.format(
								"PPA import retry %d for user file '%s' after duplicate-name error, new candidate '%s'.",
								renameAttempts,
								originalFileName,
								candidateFileName));
						continue;
					}

					// Any other error (or too many retries) should behave as before
					throw e;
				}
			}

			UserFile newUserFile = userFileRepository.getOne(newUserFileId);
			userFileByOriginalId.put(userFileDto.originalId, newUserFile);
		}

		// Create new PPA (append import date to avoid name confusion)
		Ppa newPpa = new Ppa();
		String baseName = (exportDto.name != null ? exportDto.name.trim() : "");
		String datePart = new SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
		String importedName;
		if (baseName.isEmpty())
		{
			importedName = "Imported PPA " + datePart;
		}
		else
		{
			importedName = String.format("%s (imported %s)", baseName, datePart);
		}
		newPpa.setName(importedName);
		newPpa.setAggregationLevel(exportDto.aggregationLevel != null ? exportDto.aggregationLevel : "National");
		account.addPpa(newPpa);

		// Maps for ID remapping
		Map<Long, DataSource> dataSourceByOriginalId = new HashMap<>();
		Map<Long, PpaSector> sectorByOriginalId = new HashMap<>();
		Map<Long, PpaSectorLevel> levelByOriginalId = new HashMap<>();
		Map<Long, SubnationalUnit> subnationalUnitByOriginalId = new HashMap<>();

		// DataSources
		if (exportDto.dataSources != null)
		{
			for (PpaExportDto.DataSourceDto dataSourceDto : exportDto.dataSources)
			{
				DataSource dataSource = new DataSource();
				newPpa.addDataSource(dataSource);

				if (dataSourceDto.userFileOriginalId != null)
				{
					UserFile newUserFile = userFileByOriginalId.get(dataSourceDto.userFileOriginalId);
					if (newUserFile != null)
					{
						dataSource.setUserFile(newUserFile);
					}
					// If the UserFile was skipped (e.g. data file missing from
					// archive), the DataSource is still created but without an
					// associated file. The user can re-upload the data later.
				}

				dataSource.setSubnationalUnitColumnName(dataSourceDto.subnationalUnitColumnName != null ? dataSourceDto.subnationalUnitColumnName : "");
				if (dataSourceDto.subnationalUnitValueFrequencies != null)
				{
					dataSource.setSubnationalUnitValueFrequencies(dataSourceDto.subnationalUnitValueFrequencies);
				}
				if (dataSourceDto.subnationalUnitSelectedValues != null)
				{
					dataSource.setSubnationalUnitSelectedValues(dataSourceDto.subnationalUnitSelectedValues);
				}

				dataSource.setFacilityTypeColumnName(dataSourceDto.facilityTypeColumnName != null ? dataSourceDto.facilityTypeColumnName : "");
				if (dataSourceDto.facilityTypeValues != null)
				{
					dataSource.setFacilityTypeValues(dataSourceDto.facilityTypeValues);
				}
				if (dataSourceDto.facilityTypeValueFrequencies != null)
				{
					dataSource.setFacilityTypeValueFrequencies(dataSourceDto.facilityTypeValueFrequencies);
				}

				dataSource.setHealthSectorColumnName(dataSourceDto.healthSectorColumnName != null ? dataSourceDto.healthSectorColumnName : "");
				if (dataSourceDto.healthSectorValues != null)
				{
					dataSource.setHealthSectorValues(dataSourceDto.healthSectorValues);
				}
				if (dataSourceDto.healthSectorValueFrequencies != null)
				{
					dataSource.setHealthSectorValueFrequencies(dataSourceDto.healthSectorValueFrequencies);
				}

				if (dataSourceDto.ppaSectorMappingValueCombinationFrequencies != null)
				{
					dataSource.setPpaSectorMappingValueCombinationFrequencies(dataSourceDto.ppaSectorMappingValueCombinationFrequencies);
				}

				dataSource.setSubsetColumn1Name(dataSourceDto.subsetColumn1Name != null ? dataSourceDto.subsetColumn1Name : "");
				if (dataSourceDto.subsetColumn1Values != null)
				{
					dataSource.setSubsetColumn1Values(dataSourceDto.subsetColumn1Values);
				}
				if (dataSourceDto.subsetColumn1ValueFrequencies != null)
				{
					dataSource.setSubsetColumn1ValueFrequencies(dataSourceDto.subsetColumn1ValueFrequencies);
				}
				if (dataSourceDto.subsetColumn1SelectedValues != null)
				{
					dataSource.setSubsetColumn1SelectedValues(dataSourceDto.subsetColumn1SelectedValues);
				}

				dataSource.setSubsetColumn2Name(dataSourceDto.subsetColumn2Name != null ? dataSourceDto.subsetColumn2Name : "");
				if (dataSourceDto.subsetColumn2Values != null)
				{
					dataSource.setSubsetColumn2Values(dataSourceDto.subsetColumn2Values);
				}
				if (dataSourceDto.subsetColumn2ValueFrequencies != null)
				{
					dataSource.setSubsetColumn2ValueFrequencies(dataSourceDto.subsetColumn2ValueFrequencies);
				}
				if (dataSourceDto.subsetColumn2SelectedValues != null)
				{
					dataSource.setSubsetColumn2SelectedValues(dataSourceDto.subsetColumn2SelectedValues);
				}

				dataSource.setSelectedRowCount(dataSourceDto.selectedRowCount);
				dataSource.setWeightColumnName(dataSourceDto.weightColumnName != null ? dataSourceDto.weightColumnName : "");
				if (dataSourceDto.weightMultiplier != null)
				{
					dataSource.setWeightMultiplier(dataSourceDto.weightMultiplier);
				}

				dataSourceByOriginalId.put(dataSourceDto.originalId, dataSource);
			}
		}

		// PPA sectors + levels
		if (exportDto.ppaSectors != null)
		{
			for (PpaExportDto.PpaSectorDto sectorDto : exportDto.ppaSectors)
			{
				PpaSector ppaSector = new PpaSector();
				newPpa.addPpaSector(ppaSector);

				ppaSector.setPosition(sectorDto.position);
				ppaSector.setName(sectorDto.name != null ? sectorDto.name : "");
				ppaSector.setEditable(sectorDto.editable);
				ppaSector.setSelected(sectorDto.selected);

				sectorByOriginalId.put(sectorDto.originalId, ppaSector);
			}
		}

		if (exportDto.ppaSectorLevels != null)
		{
			for (PpaExportDto.PpaSectorLevelDto levelDto : exportDto.ppaSectorLevels)
			{
				PpaSector parentSector = sectorByOriginalId.get(levelDto.ppaSectorOriginalId);
				if (parentSector == null)
				{
					continue;
				}

				PpaSectorLevel level = new PpaSectorLevel();
				parentSector.addPpaSectorLevel(level);
				level.setLevel(levelDto.level != null ? levelDto.level : "");

				levelByOriginalId.put(levelDto.originalId, level);
			}
		}

		// Flush sectors+levels so that PpaSectorLevel entities receive their IDs
		// before PpaSectorMapping objects reference them (the @ManyToOne from
		// PpaSectorMapping to PpaSectorLevel has no cascade).
		ppaRepository.flush();

		// Subnational units
		if (exportDto.subnationalUnits != null)
		{
			for (PpaExportDto.SubnationalUnitDto unitDto : exportDto.subnationalUnits)
			{
				SubnationalUnit unit = new SubnationalUnit();
				newPpa.addSubnationalUnit(unit);
				unit.setName(unitDto.name != null ? unitDto.name : "");

				subnationalUnitByOriginalId.put(unitDto.originalId, unit);
			}
		}

		// Metrics
		if (exportDto.metrics != null)
		{
			for (PpaExportDto.MetricDto metricDto : exportDto.metrics)
			{
				Metric metric = new Metric();
				newPpa.addMetric(metric);

				if (metricDto.dataSourceOriginalId != null)
				{
					DataSource ds = dataSourceByOriginalId.get(metricDto.dataSourceOriginalId);
					metric.setDataSource(ds);
				}

				if (metricDto.metricTypeId != null)
				{
					MetricType metricType = metricTypeRepository.getOne(metricDto.metricTypeId);
					metric.setMetricType(metricType);
				}

				metric.setSelected(metricDto.selected);
				metric.setDataPointName(metricDto.dataPointName != null ? metricDto.dataPointName : "");
				metric.setDataSourceColumnName(metricDto.dataSourceColumnName != null ? metricDto.dataSourceColumnName : "");

				if (metricDto.columnValueFrequencies != null)
				{
					metric.setColumnValueFrequencies(metricDto.columnValueFrequencies);
				}
				if (metricDto.selectedColumnValues != null)
				{
					metric.setSelectedColumnValues(metricDto.selectedColumnValues);
				}
			}
		}

		// Sector mappings
		if (exportDto.ppaSectorMappings != null)
		{
			for (PpaExportDto.PpaSectorMappingDto mappingDto : exportDto.ppaSectorMappings)
			{
				DataSource ds = dataSourceByOriginalId.get(mappingDto.dataSourceOriginalId);
				PpaSectorLevel level = levelByOriginalId.get(mappingDto.ppaSectorLevelOriginalId);

				if (ds == null || level == null)
				{
					continue;
				}

				PpaSectorMapping mapping = new PpaSectorMapping();
				ds.addPpaSectorMapping(mapping);
				level.addPpaSectorMapping(mapping);
				mapping.setValueCombination(mappingDto.valueCombination != null ? mappingDto.valueCombination : "");
			}
		}

		// Subnational mappings
		if (exportDto.subnationalUnitMappings != null)
		{
			for (PpaExportDto.SubnationalUnitMappingDto mappingDto : exportDto.subnationalUnitMappings)
			{
				DataSource ds = dataSourceByOriginalId.get(mappingDto.dataSourceOriginalId);
				SubnationalUnit unit = subnationalUnitByOriginalId.get(mappingDto.subnationalUnitOriginalId);

				if (ds == null || unit == null)
				{
					continue;
				}

				SubnationalUnitMapping mapping = new SubnationalUnitMapping();
				ds.addSubnationalUnitMapping(mapping);
				unit.addSubnationalUnitMapping(mapping);
				mapping.setRegionColumnValue(mappingDto.regionColumnValue != null ? mappingDto.regionColumnValue : "");
			}
		}

		// Ensure everything is flushed so that IDs are assigned
		ppaRepository.flush();

		// Return basic info for the frontend to auto-select the imported PPA
		return ImmutableMap.of("ppaId", newPpa.getId(), "name", newPpa.getName());
	}

	/**
	 * Generates a user-friendly file name for imported user files that is
	 * guaranteed to be unique within the given account. If the original name is
	 * already free, it's returned unchanged; otherwise an "imported" suffix with
	 * the current date (and, if needed, an incrementing number) is appended.
	 */
	private String generateUniqueUserFileNameForImport(Account account, String originalFileName)
	{
		if (account == null || StringUtils.isBlank(originalFileName))
		{
			return originalFileName;
		}

		String extension = FilenameUtils.getExtension(originalFileName);
		String baseName = FilenameUtils.getBaseName(originalFileName);

		// Start with the original name; if it collides, append " (imported yyyy-MM-dd)"
		// and, if necessary, " (imported yyyy-MM-dd N)" variants until we find a free one.
		String candidate = originalFileName;
		String datePart = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
		int counter = 0;

		while (!userFileRepository.findAllByAccountIdAndFileName(account.getId(), candidate).isEmpty())
		{
			counter++;

			String suffix;
			if (counter == 1)
			{
				suffix = String.format(" (imported %s)", datePart);
			}
			else
			{
				suffix = String.format(" (imported %s %d)", datePart, counter);
			}

			if (StringUtils.isBlank(extension))
			{
				candidate = baseName + suffix;
			}
			else
			{
				candidate = baseName + suffix + "." + extension;
			}
		}

		return candidate;
	}

	@RequestMapping(value = "/duplicatePpas")
	@ResponseBody
	@Transactional
	public void duplicatePpas
	(
			@RequestParam(value = "ppaIds[]") List<Long> ppaIds,
			Principal principal
	)
	{
		User user = (principal != null ? userRepository.findByUsername(principal.getName()) : getUser());
		
		// get objects
		
		List<Ppa> ppas = ppaRepository.findByIdIn(ppaIds);
		
		// update database
		
		for (Ppa ppa : ppas)
		{
			// clone ppa
			
			Ppa newPpa = (Ppa)cloneEntity(ppa);
			user.getSelectedAccount().addPpa(newPpa);
			
			userRepository.flush();
			ppaRepository.refresh(newPpa);
			
			// modify ppa name
			
			newPpa.setName(ppa.getName() + " - Copy");
			
			// clone dataSources
			
			Map<DataSource, DataSource> clonedDataSources = new HashMap<>();
			for (DataSource dataSource : ppa.getDataSources())
			{
				DataSource newDataSource = (DataSource)cloneEntity(dataSource);
				newPpa.addDataSource(newDataSource);
				
				ppaRepository.flush();
				dataSourceRepository.refresh(newDataSource);
				
				clonedDataSources.put(dataSource, newDataSource);
				
			}
			
			// clone metrics
			
			Map<Metric, Metric> clonedMetrics = new HashMap<>();
			for (Metric metric : ppa.getMetrics())
			{
				Metric newMetric = (Metric)cloneEntity(metric);
				newPpa.addMetric(newMetric);
				
				ppaRepository.flush();
				metricRepository.refresh(newMetric);
				
				clonedMetrics.put(metric, newMetric);
				
				// reassign data source
				
				newMetric.setDataSource(clonedDataSources.get(metric.getDataSource()));
				
			}
			
			// clone ppaSectors
			
			Map<PpaSector, PpaSector> clonedPpaSectors = new HashMap<>();
			for (PpaSector ppaSector : ppa.getPpaSectors())
			{
				PpaSector newPpaSector = (PpaSector)cloneEntity(ppaSector);
				newPpa.addPpaSector(newPpaSector);
				
				ppaRepository.flush();
				ppaSectorRepository.refresh(newPpaSector);
				
				clonedPpaSectors.put(ppaSector, newPpaSector);
				
			}
			
			// clone subnationalUnits
			
			Map<SubnationalUnit, SubnationalUnit> clonedSubnationalUnits = new HashMap<>();
			for (SubnationalUnit subnationalUnit : ppa.getSubnationalUnits())
			{
				SubnationalUnit newSubnationalUnit = (SubnationalUnit)cloneEntity(subnationalUnit);
				newPpa.addSubnationalUnit(newSubnationalUnit);
				
				ppaRepository.flush();
				subnationalUnitRepository.refresh(newSubnationalUnit);
				
				clonedSubnationalUnits.put(subnationalUnit, newSubnationalUnit);
				
			}
			
			// clone outputs
			
			Map<Output, Output> clonedOutputs = new HashMap<>();
			for (Output output : ppa.getOutputs())
			{
				Output newOutput = (Output)cloneEntity(output);
				newPpa.addOutput(newOutput);
				
				ppaRepository.flush();
				outputRepository.refresh(newOutput);
				
				clonedOutputs.put(output, newOutput);
				
			}
			
			// clone ppaSectorMappings
			
			for (PpaSector ppaSector : ppa.getPpaSectors())
			{
				for (PpaSectorLevel ppaSectorLevel : ppaSector.getPpaSectorLevels())
				{
					PpaSectorLevel newPpaSectorLevel = (PpaSectorLevel)cloneEntity(ppaSectorLevel);
					clonedPpaSectors.get(ppaSector).addPpaSectorLevel(newPpaSectorLevel);
					
					ppaSectorRepository.flush();
					ppaSectorLevelRepository.refresh(newPpaSectorLevel);

					for (PpaSectorMapping ppaSectorMapping : ppaSectorLevel.getPpaSectorMappings())
					{
						PpaSectorMapping newPpaSectorMapping = (PpaSectorMapping)cloneEntity(ppaSectorMapping);
						newPpaSectorLevel.addPpaSectorMapping(newPpaSectorMapping);
						
						// reassign data source
						
						newPpaSectorMapping.setDataSource(clonedDataSources.get(ppaSectorMapping.getDataSource()));
						
					}
					
				}
				
			}
			
			// clone subnationalUnitMappings
			
			for (SubnationalUnit subnationalUnit : ppa.getSubnationalUnits())
			{
				for (SubnationalUnitMapping subnationalUnitMapping : subnationalUnit.getSubnationalUnitMappings())
				{
					SubnationalUnitMapping newSubnationalUnitMapping = (SubnationalUnitMapping)cloneEntity(subnationalUnitMapping);
					clonedSubnationalUnits.get(subnationalUnit).addSubnationalUnitMapping(newSubnationalUnitMapping);
					
					// reassign data source
					
					newSubnationalUnitMapping.setDataSource(clonedDataSources.get(subnationalUnitMapping.getDataSource()));
					
				}
				
			}
			
		}

	}

	@RequestMapping(value = "/getPpaName")
	@ResponseBody
	public Map<String, Object> getPpaName
	(
			@RequestParam(value = "ppaId") Long ppaId
	)
	{
		Ppa ppa = ppaRepository.getOne(ppaId);
		
		return ImmutableMap.of("ppaName", ppa.getName());

	}

	@RequestMapping(value = "/setPpaName")
	@ResponseBody
	@Transactional
	public void setPpaName
	(
			@RequestParam(value = "ppaId") Long ppaId,
			@RequestParam(value = "ppaName") String ppaName
	)
	{
		Ppa ppa = ppaRepository.getOne(ppaId);
		
		ppa.setName(ppaName);

	}

	@RequestMapping(value = "/getPpaRegion")
	@ResponseBody
	public Map<String, Object> getPpaRegion
	(
			@RequestParam(value = "ppaId") Long ppaId
	)
	{
		Ppa ppa = ppaRepository.getOne(ppaId);
		
		return ImmutableMap.of("region", ppa.getAggregationLevel());

	}

	@RequestMapping(value = "/setPpaAggregationLevel")
	@ResponseBody
	@Transactional
	public void setPpaAggregationLevel
	(
			@RequestParam(value = "ppaId") Long ppaId,
			@RequestParam(value = "ppaAggregationLevel") String ppaAggregationLevel
	)
	{
		// get PPA
		
		Ppa ppa = ppaRepository.getOne(ppaId);
		
		// set aggregationLevel
		
		ppa.setAggregationLevel(ppaAggregationLevel);
		
	}

	@RequestMapping(value = "/selectPpa")
	@Transactional
	public void selectPpa
	(
			@RequestParam(value = "ppaId") Long ppaId
	)
	{
		User user = getUser();
		Account account = user.getSelectedAccount();
		Ppa ppa = ppaRepository.getOne(ppaId);
		
		AccountUserAssociation accountUserAssociation = accountUserAssociationRepository.findByAccountAndUser(account, user);
		
		accountUserAssociation.setSelectedPpa(ppa);
		
	}

	@RequestMapping(value = "/getDataSources")
	@ResponseBody
	public List<Map<String, Object>> getDataSources
	(
			@RequestParam(value = "subnationalUnitColumnNameSet", required = false) Boolean subnationalUnitColumnNameSet
	)
	{
		// get selected PPA
		
		Ppa ppa = getSelectedPpa(true);
		
		// get PPA associated dataSources
		
		Set<DataSource> metricDataSources = getPpaAssociatedDataSources(ppa);
		
		// populate output
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (DataSource dataSource : metricDataSources)
		{
			if
			(
					(subnationalUnitColumnNameSet == null || StringUtils.isNotEmpty(dataSource.getSubnationalUnitColumnName()) == subnationalUnitColumnNameSet.booleanValue())
			)
			{
				Map<String, Object> dataSourceRow = new HashMap<>();
				output.add(dataSourceRow);
				
				dataSourceRow.put("id", dataSource.getId());
				dataSourceRow.put("fileName", dataSource.getUserFile().getFileName());
				dataSourceRow.put("weightColumnName", dataSource.getWeightColumnName());
				dataSourceRow.put("weightMultiplier", dataSource.getWeightMultiplier());
				dataSourceRow.put("subnationalUnitColumnName", dataSource.getSubnationalUnitColumnName());
				dataSourceRow.put("allPpaSectorLevelsMapped", isDataSourceAllPpaSectorLevelsMapped(dataSource));
				dataSourceRow.put("allAggregationLevelsMapped", isDataSourceAllAggregationLevelsMapped(dataSource));
				
			}
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/getPpaSectorLevelMappingDataSources")
	@ResponseBody
	public List<Map<String, Object>> getPpaSectorLevelMappingDataSources
	(
	)
	{
		// get selected PPA
		
		Ppa ppa = getSelectedPpa(true);
		
		// get PPA associated dataSources
		
		Set<DataSource> metricDataSources = getPpaAssociatedDataSources(ppa);
		
		// populate output
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (DataSource dataSource : metricDataSources)
		{
			Map<String, Object> dataSourceRow = new HashMap<>();
			output.add(dataSourceRow);
			
			dataSourceRow.put("id", dataSource.getId());
			dataSourceRow.put("fileName", dataSource.getUserFile().getFileName());
			
			// mapped
			
			if (StringUtils.isEmpty(dataSource.getHealthSectorColumnName()) && StringUtils.isEmpty(dataSource.getFacilityTypeColumnName()))
			{
				dataSourceRow.put("mapped", "columnNotSet");
				
			}
			else
			{
				dataSourceRow.put("mapped", isDataSourceAllPpaSectorLevelsMapped(dataSource) ? "yes" : "no");
				
			}
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/getAggregationLevelMappingDataSources")
	@ResponseBody
	public List<Map<String, Object>> getAggregationLevelMappingDataSources
	(
	)
	{
		// get selected PPA
		
		Ppa ppa = getSelectedPpa(true);
		
		// get PPA associated dataSources
		
		Set<DataSource> metricDataSources = getPpaAssociatedDataSources(ppa);
		
		// populate output
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (DataSource dataSource : metricDataSources)
		{
			Map<String, Object> dataSourceRow = new HashMap<>();
			output.add(dataSourceRow);
			
			dataSourceRow.put("id", dataSource.getId());
			dataSourceRow.put("fileName", dataSource.getUserFile().getFileName());
			dataSourceRow.put("aggregationLevel", ppa.getAggregationLevel());
			
			// mapped
			
			if (StringUtils.isEmpty(dataSource.getSubnationalUnitColumnName()))
			{
				dataSourceRow.put("mapped", "columnNotSet");
				
			}
			else
			{
				dataSourceRow.put("mapped", isDataSourceAllAggregationLevelsMapped(dataSource) ? "yes" : "no");
				
			}
			
		}
		
		return output;
		
	}
	
	/**
	 * Loads file to S3 and associates it with existing userFile.
	 * Loads file content to database.
	 * 
	 * @param file
	 * @return
	 */
	@RequestMapping(value = "/loadUserFile")
	@Transactional
	public Map<String, Object> loadUserFile
	(
			@RequestParam(value = "file") MultipartFile file
	)
	{
		// test Rserve connection
		
		System.out.println("test Rserve connection");
		testRserveConnection();
		
		// get account
		
		System.out.println("get account");
		Account account = getUser().getSelectedAccount();
		
		// generate file related properties
		
		System.out.println("generate file related properties");
		String fileName = file.getOriginalFilename();
		String fileNameExtension = FilenameUtils.getExtension(fileName).toLowerCase();
		
		// check file extension
		
		System.out.println("check file extension");
		if (!rFileTypeReadCommands.containsKey(fileNameExtension))
		{
			throw new ApplicationException("Unsupported file extension. Supported values are " + StringUtils.join(rFileTypeReadCommands.keySet(), ','));
			
		}
		
		// check duplicate fileName
		
		System.out.println("check duplicate fileName");
		Set<UserFile> userFiles = userFileRepository.findAllByAccountIdAndFileName(account.getId(), fileName);
		if (userFiles.size() >= 1)
		{
			throw new ApplicationException("You have already loaded file with this name.");
			
		}
		
		// generate unique s3Key (logical key used both for S3 and for the
		// local /s3 mount in LOCAL_MODE)
		
		System.out.println("generate unique s3Key");
		String s3FileName;
		do
		{
			s3FileName = String.format("%s/%s", s3UserFileDirectory, String.format("%s.%s", UUID.randomUUID().toString(), fileNameExtension));
			
		}
		while (userFileRepository.findByS3FileName(s3FileName).size() >= 1);
		
		// build s3MountPath
		
		System.out.println("build s3MountPath");
		String s3MountPathHost = getS3MountPath(s3FileName);
		String s3MountPathR = getS3MountPathR(s3FileName);
		
		// create userFile
		
		System.out.println("create userFile");
		UserFile userFile = new UserFile();
		account.addUserFile(userFile);
		
		userFile.setFileName(fileName);
		userFile.setS3FileName(s3FileName);
		
		userFileRepository.save(userFile);
		userFileRepository.refresh(userFile);
		
		RConnection rConnection = null;
		try
		{
			// Store the uploaded file. In LOCAL_MODE we write directly to the
			// /s3 mount; otherwise we upload to S3 as in the original app.
			
			if (localMode)
			{
				System.out.println("LOCAL_MODE enabled – saving uploaded file to local /s3 mount instead of S3");
				
				try (InputStream in = file.getInputStream())
				{
					Path targetPath = Paths.get(s3MountPathHost);
					Files.createDirectories(targetPath.getParent());
					Files.copy(in, targetPath, StandardCopyOption.REPLACE_EXISTING);
				}
				catch (IOException e)
				{
					throw new ApplicationException("Could not save uploaded file locally.<br/>" + e.getMessage());
				}
			}
			else
			{
				System.out.println("upload file to S3");
				Exception exception = null;
				for (int attemptCount = 0; attemptCount < 3; attemptCount++)
				{
					try
					{
						ObjectMetadata objectMetadata = new ObjectMetadata();
						objectMetadata.setContentLength(file.getSize());
						
						Upload upload = transferManager.upload(s3Bucket, s3FileName, file.getInputStream(), objectMetadata);
						
						System.out.println("upload.waitForCompletion()");
						upload.waitForCompletion();
						
						// exit loop
						
						break;
						
					}
					catch (AmazonClientException | InterruptedException | IOException e)
					{
						// store error
						
						exception = e;
						
						// ignore error
						
						e.printStackTrace();
						
					}
					
				}
				
				if (exception != null)
				{
					// could not upload after multiple attempts - show error
					
					System.out.println("could not upload after multiple attempts - show error");
					System.out.println(exception.getMessage());
					throw new ApplicationException("Could not load file to S3 after 3 attempts.<br/>" + exception.getMessage());
					
				}
			}
			
			// build file read command
			
			System.out.println("build file read command");
			String fileReadCommand = String.format(rFileTypeReadCommands.get(fileNameExtension), s3MountPathR);
			
			// extract data
			
			rConnection = getRserveConnection();
			
			rEval(rConnection, "library('foreign')");
			
			// Always return a message string (empty string means success). This avoids relying
			// on R's "invisible" return values which can show up as NULL in Rserve.
			REXP messageRexp =
					rEval
					(
							rConnection,
							String.format
							(
									"local({ msg <- tryCatch({ df <- %s; '' }, warning=function(w){w[['message']]}, error=function(e){e[['message']]}); msg })",
									fileReadCommand
							)
					)
			;
			
			String messageString = "";
			if (messageRexp instanceof REXPString)
			{
				try
				{
					messageString = ((REXPString)messageRexp).asString();
				}
				catch (REXPMismatchException e)
				{
					throw new RuntimeException(e);
				}
			}
			
			if (StringUtils.isNotBlank(messageString))
			{
				String messageLower = messageString.toLowerCase();
				
				if (messageLower.contains("cannot open file"))
				{
					throw new ApplicationException("Cannot open file.");
				}
				else if (messageLower.contains("invalid input found"))
				{
					// get number of successfully loaded rows
					
					REXP nrowRexp =
							rEval
							(
									rConnection,
									String.format
									(
											"nrow(%s)",
											fileReadCommand
									)
							)
					;
					
					int nrows;
					try
					{
						nrows = ((REXPInteger)nrowRexp).asInteger();
					}
					catch (REXPMismatchException e)
					{
						throw new RuntimeException(e);
					}
					
					throw new ApplicationException("Cannot read file. Please ensure file is stored in UTF-8 encoding.<br/><br/>Number of data rows loaded: " + nrows + ".");
				}
				
				// fallback: return the message from R
				throw new ApplicationException(messageString);
			}
			
			// Ensure df exists and isn't NULL before continuing.
			REXP dfOkRexp = rEval(rConnection, "exists('df') && !is.null(df)");
			boolean dfOk;
			try
			{
				dfOk = ((org.rosuda.REngine.REXPLogical)dfOkRexp).asIntegers()[0] == 1;
			}
			catch (Exception e)
			{
				dfOk = false;
			}
			
			if (!dfOk)
			{
				throw new ApplicationException(
						String.format(
								"Cannot open file. R did not load data frame 'df'.<br/><br/>R path: %s<br/>Host path: %s<br/><br/>If Rserve runs in Docker, ensure the host path is mounted into the container at the R path.",
								escapeRStringLiteral(String.valueOf(s3MountPathR)),
								escapeRStringLiteral(String.valueOf(s3MountPathHost))
						)
				);
			}
			
			// get column names
			
			REXP colnamesRexp = rEval(rConnection, "colnames(df)");
			if (!(colnamesRexp instanceof REXPString))
			{
				throw new ApplicationException("Cannot read column names from file.");
			}
			String[] columnNames = ((REXPString)colnamesRexp).asStrings();
			
			// set userFile column names
			
			userFile.setColumnNames(columnNames);
			
			// set userfile nrow
			
			userFileRepository.save(userFile);
			
			// convert data frame values to text
			
			rEval(rConnection, "df[] <- lapply(df, as.character)");
			
			// replace NA to string
			
			rEval(rConnection, "df[is.na(df)] <- \"N/A\"");
			
			// trim values
			
			rEval(rConnection, "df[] <- lapply(df, trimws)");
			
			// store content
			
			rEval(rConnection, "library('RPostgreSQL')");
			rEval(rConnection, "drv <- dbDriver(drvName='PostgreSQL')");
			rEval
			(
					rConnection,
					String.format
					(
							"con <- dbConnect(drv = drv, host = '%s', port = '%s', dbname = '%s', user = '%s', password = '%s')",
							datasourceHost,
							datasourcePort,
							datasourceDatabase,
							datasourceUsername,
							datasourcePassword
					)
			)
			;
			
			int ncol;
			try
			{
				ncol = ((REXPInteger)rEval(rConnection, "ncol(df)")).asInteger();
				
			}
			catch (REXPMismatchException e)
			{
				throw new ApplicationException(e);
				
			}
			
			for (int sectionIndex = 0; sectionIndex < getColumnSectionIndex(ncol - 1) + 1 ; sectionIndex++)
			{
				String tableName = String.format("%s_%d_%d", FILE_TABLE_NAME_PREFIX, userFile.getId(), sectionIndex);
				int[] columnIndexRange = getSectionColumnIndexRange(sectionIndex);
				int firstColumnNumber = columnIndexRange[0] + 1;
				int lastColumnNumber = Math.min(ncol, columnIndexRange[1]);
				
				rEval
				(
						rConnection,
						String.format
						(
								"dbWriteTable(conn = con, name = '%s', value = df[,%d:%d], row.names = TRUE, overwrite = TRUE, append = FALSE)",
								tableName,
								firstColumnNumber,
								lastColumnNumber
						)
				)
				;
				
			}
			
		}
		catch (ApplicationException e)
		{
			// delete userFile content
			
			deleteUserFileContent(userFile);
			
			// delete uploaded file from storage (local filesystem in LOCAL_MODE,
			// S3 in hosted/cloud mode)
			
			try
			{
				if (localMode)
				{
					Files.deleteIfExists(Paths.get(s3MountPathHost));
					
				}
				else
				{
					amazonS3.deleteObject(s3Bucket, s3FileName);
					
				}
				
			}
			catch (AmazonClientException | IOException e1)
			{
				throw new ApplicationException(e);
				
			}
			
			// rethrow ApplicationException
			
			throw e;
			
		}
		finally
		{
			if (rConnection != null) rConnection.close();

		}
        
		// return userFile Id
		
		return ImmutableMap.of("userFileId", userFile.getId());
		
	}
	
	/**
	 * Loads user file and assigns it to the given metric.
	 * 
	 * @param file
	 * @param metricId
	 */
	@RequestMapping(value = "/loadUserFileAndAssignItToMetric")
	@Transactional
	public void loadUserFileAndAssignItToMetric
	(
			@RequestParam(value = "file") MultipartFile file,
			@RequestParam(value = "metricId") Long metricId
	)
	{
		// load userFile
		
		Map<String, Object> loadUserFileResponse = loadUserFile(file);
		Long userFileId = (Long)loadUserFileResponse.get("userFileId");
		
		if (userFileId == null)
		{
			throw new ApplicationException("System error. Method loadUserFile didn't return userFileId.");
			
		}
		
		// set metric userFile
		
		setMetricUserFile(metricId, userFileId);
		
	}

	@RequestMapping(value = "/deleteUserFiles")
	@Transactional
	public void deleteUserFiles
	(
			@RequestParam(value = "userFileIds[]") Set<Long> userFileIds
	)
	{
		// get account
		
		Account account = getUser().getSelectedAccount();
		
		// get userFiles
		
		Set<UserFile> userFiles = userFileRepository.findByIdIn(userFileIds);
		
		// update database
		
		List<String> s3Keys = new ArrayList<>();
		
		for (UserFile userFile : userFiles)
		{
			// delete dataSources
			
			List<Long> dataSourceIds = new ArrayList<>();
			
			for (DataSource dataSource : userFile.getDataSources())
			{
				dataSourceIds.add(dataSource.getId());
				
			}
			
			deleteDataSources(dataSourceIds);
			
			// collect S3 file name
			
			s3Keys.add(userFile.getS3FileName());
			
			// remove userFile
			
			account.removeUserFile(userFile);
			
			// delete userFile content
			
			deleteUserFileContent(userFile);
			
		}
		
		// delete files from S3 (cloud mode only)
		
		if (!localMode)
		{
			for (String s3Key : s3Keys)
			{
				try
				{
					amazonS3.deleteObject(s3Bucket, s3Key);
					
				}
				catch (AmazonClientException e)
				{
					throw new ApplicationException(e);
					
				}
				
			}
		}
		
	}

//	@RequestMapping(value = "/createDataSource")
//	@ResponseBody
//	@Transactional
//	public void createDataSource
//	(
//			@RequestParam(value = "file") MultipartFile file,
//			@RequestParam(value = "metricId", required = false) Long metricId
//	)
//	{
//		// get selected PPA
//		
//		Ppa selectedPpa = getSelectedPpa(true);
//		
//		// create default metrics
//		
//		createDefaultPpaMetrics();
//		
//		String originalFileName = file.getOriginalFilename();
//		String originalFileNameExtension = FilenameUtils.getExtension(originalFileName).toLowerCase();
//		String[] columnNames;
//		
//		// generate unique s3Key
//		
//		String s3Key;
//		do
//		{
//			s3Key = String.format("%s/%s", s3UserFileDirectory, String.format("%s.%s", UUID.randomUUID().toString(), originalFileNameExtension));
//			
//		}
//		while (dataSourceRepository.findByS3FileName(s3Key).size() >= 1);
//		
//		// check file extension
//		
//		if (!rFileTypeReadCommands.containsKey(originalFileNameExtension))
//		{
//			throw new ApplicationException("Unsupported file extension. Supported values are " + StringUtils.join(rFileTypeReadCommands.keySet(), ','));
//			
//		}
//		
//		// test Rserve connection
//		
//		testRserveConnection();
//		
//		// upload file to S3
//		
//		Exception exception = null;
//		for (int attemptCount = 0; attemptCount < 3; attemptCount++)
//		{
//			try
//			{
//				ObjectMetadata objectMetadata = new ObjectMetadata();
//				objectMetadata.setContentLength(file.getSize());
//				
//				Upload upload = transferManager.upload(s3Bucket, s3Key, file.getInputStream(), objectMetadata);
//				
//				upload.waitForCompletion();
//				
//				// exit loop
//				
//				break;
//				
//			}
//			catch (AmazonClientException | InterruptedException | IOException e)
//			{
//				// store error
//				
//				exception = e;
//				
//				// ignore error
//				
//				e.printStackTrace();
//				
//			}
//			
//		}
//		
//		if (exception != null)
//		{
//			// could not upload after multiple attempts - show error
//			
//			throw new ApplicationException("Could not load file to S3 after 3 attempts.<br/>" + exception.getMessage());
//			
//		}
//		
//		// extract column names
//		
//		RConnection rConnection = null;
//		try
//		{
//			rConnection = getRserveConnection();
//			
//			rEval(rConnection, "library('foreign')");
//			rEval(rConnection, "df<-" + String.format(rFileTypeReadCommands.get(originalFileNameExtension), getS3MountPath(s3Key)));
//			
//			// get column names
//			
//			columnNames = ((REXPString)rEval(rConnection, "colnames(df)")).asStrings();
//				
//		}
//		catch (ApplicationException e)
//		{
//			// delete S3 file
//			
//			try
//			{
//				amazonS3.deleteObject(s3Bucket, s3Key);
//				
//			}
//			catch (AmazonClientException e1)
//			{
//				throw new ApplicationException(e);
//				
//			}
//			
//			// rethrow ApplicationException
//			
//			throw e;
//			
//		}
//        finally
//        {
//			if (rConnection != null) rConnection.close();
//
//        }
//        
//		// update database
//		
//		DataSource dataSource = new DataSource();
//		
//		dataSource.setFileName(originalFileName);
//		dataSource.setS3FileName(s3Key);
//		dataSource.setColumnNames(columnNames);
//		
//		selectedPpa.addDataSource(dataSource);
//		
//		// link data source with global variables
//		
//		for (Metric ppaMetric : selectedPpa.getMetrics())
//		{
//			if
//			(
//					METRIC_TYPE_FACILITY_TYPE.equals(ppaMetric.getMetricType().getType())
//					||
//					METRIC_TYPE_HEALTH_SECTOR.equals(ppaMetric.getMetricType().getType())
//					||
//					METRIC_TYPE_REGION.equals(ppaMetric.getMetricType().getType())
//			)
//			{
//				ppaMetric.addDataSource(dataSource);
//				
//			}
//			
//		}
//		
//		// save and refresh
//		
//		dataSourceRepository.save(dataSource);
//		dataSourceRepository.refresh(dataSource);
//		
//		// assign dataSource to ppaMetric
//		
//		if (metricId != null)
//		{
//			setMetricDataSource(metricId, dataSource.getId());
//			
//		}
//		
//	}
//
	@RequestMapping(value = "/deleteDataSources")
	@ResponseBody
	@Transactional
	public void deleteDataSources
	(
			@RequestParam(value = "dataSourceIds[]") List<Long> dataSourceIds
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// get dataSources
		
		List<DataSource> dataSources = dataSourceRepository.findByIdIn(dataSourceIds);
		
		// update database
		
		for (DataSource dataSource : dataSources)
		{
			selectedPpa.removeDataSource(dataSource);
			
			// remove all metric-dataSource associations
			
			for (Metric metric : dataSource.getMetrics())
			{
				metric.setDataSource(null);
				metric.setDataSourceColumnName("");
				metric.setColumnValueFrequencies(new HashMap<>());
				metric.setSelectedColumnValues(new String[] {});
				
			}
			
		}

	}

	@RequestMapping(value = "/setDataSourceWeightColumnName")
	@ResponseBody
	@Transactional
	public void setDataSourceWeightColumnName
	(
			@RequestParam(value = "dataSourceId") Long dataSourceId,
			@RequestParam(value = "weightColumnName") String weightColumnName
	)
	{
		DataSource dataSource = getDataSource(dataSourceId);
		
		// update database
		
		dataSource.setWeightColumnName(weightColumnName);
		
	}

	@RequestMapping(value = "/setDataSourceWeightMultiplier")
	@ResponseBody
	@Transactional
	public void setDataSourceWeightMultiplier
	(
			@RequestParam(value = "dataSourceId") Long dataSourceId,
			@RequestParam(value = "weightMultiplier") BigDecimal weightMultiplier
	)
	{
		DataSource dataSource = getDataSource(dataSourceId);
		
		// update database
		
		dataSource.setWeightMultiplier(weightMultiplier);
		
	}

	@RequestMapping(value = "/getDataSourceSubsets")
	@ResponseBody
	public List<Map<String, Object>> getDataSourceSubsets
	(
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// get PPA associated dataSources
		
		Set<DataSource> associatedDataSources = getPpaAssociatedDataSources(selectedPpa);
		
		// populate output
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (DataSource dataSource : associatedDataSources)
		{
			Map<String, Object> outputRow = new HashMap<>();
			output.add(outputRow);
			
			outputRow.put("id", dataSource.getId());
			outputRow.put("fileName", dataSource.getUserFile().getFileName());
			outputRow.put("subnationalUnitColumnName", dataSource.getSubnationalUnitColumnName());
			
			// subset columns
			
			Map<String, Object> dataSourceSubsetCounts = getDataSourceSubsetCounts(dataSource);
			
			outputRow.putAll(dataSourceSubsetCounts);
			
		}
		
		return output;
		
	}

	@RequestMapping(value = "/setDataSourceSubsetColumn1Name")
	@ResponseBody
	@Transactional
	public Map<String, Object> setDataSourceSubsetColumn1Name
	(
			@RequestParam(value = "dataSourceId") Long id,
			@RequestParam(value = "subsetColumn1Name") String columnName
	)
	{
		DataSource dataSource = dataSourceRepository.getOne(id);
		
		// get column values
		
		Map<String, Long> columnValueFrequencies = extractDataSouceColumnValueFrequencies(dataSource, columnName, false);
		
		// update database
		
		dataSource.setSubsetColumn1Name(columnName);
		dataSource.setSubsetColumn1Values(columnValueFrequencies.keySet().toArray(new String[] {}));
		dataSource.setSubsetColumn1ValueFrequencies(columnValueFrequencies);
		dataSource.setSubsetColumn1SelectedValues(columnValueFrequencies.keySet().toArray(new String[] {}));
		
		// update subset based values
		
		updateSubsetBasedValues(dataSource);
		
		// return update
		
		return getDataSourceSubsetCounts(dataSource);
		
	}

	@RequestMapping(value = "/setDataSourceSubsetColumn2Name")
	@ResponseBody
	@Transactional
	public Map<String, Object> setDataSourceSubsetColumn2Name
	(
			@RequestParam(value = "dataSourceId") Long id,
			@RequestParam(value = "subsetColumn2Name") String columnName
	)
	{
		DataSource dataSource = dataSourceRepository.getOne(id);
		
		// get column values
		
		Map<String, Long> columnValueFrequencies = extractDataSouceColumnValueFrequencies(dataSource, columnName, false);
		
		// update database
		
		dataSource.setSubsetColumn2Name(columnName);
		dataSource.setSubsetColumn2Values(columnValueFrequencies.keySet().toArray(new String[] {}));
		dataSource.setSubsetColumn2ValueFrequencies(columnValueFrequencies);
		dataSource.setSubsetColumn2SelectedValues(columnValueFrequencies.keySet().toArray(new String[] {}));
		
		// update subset based values
		
		updateSubsetBasedValues(dataSource);
		
		// return update
		
		return getDataSourceSubsetCounts(dataSource);
		
	}

	@RequestMapping(value = "/getDataSourceSubsetColumn1Values")
	@ResponseBody
	public Map<String, Object> getDataSourceSubsetColumn1Values
	(
			@RequestParam(value = "dataSourceId", required = false) Long dataSourceId
	)
	{
		Map<String, Object> output = new HashMap<>();
		
		// skip empty requests
		
		if (dataSourceId == null)
		{
			output.put("total", 0);
			output.put("rows", new ArrayList<>());
			
			return output;
			
		}
		
		// get dataSource
		
		Optional<DataSource> optionalDataSource = dataSourceRepository.findById(dataSourceId);
		
		if (!optionalDataSource.isPresent())
		{
			throw new ApplicationException("Data source is not found with given id: " + dataSourceId + ".");
			
		}
		
		DataSource dataSource = optionalDataSource.get();
		
		// populate output
		
		List<Map<String, Object>> rows = new ArrayList<>();
		output.put("rows", rows);
		
		Set<String> selectedValues = new HashSet<String>(Arrays.asList(dataSource.getSubsetColumn1SelectedValues()));
		
		List<Map.Entry<String, Long>> valueFrequencies = new ArrayList<Map.Entry<String, Long>>(dataSource.getSubsetColumn1ValueFrequencies().entrySet());
		output.put("total", valueFrequencies.size());
		
		for (Map.Entry<String, Long> valueFrequencyEntry : valueFrequencies)
		{
			String value = valueFrequencyEntry.getKey();
			Long frequency = valueFrequencyEntry.getValue();
			
			Map<String, Object> row = new HashMap<>();
			rows.add(row);
			
			row.put("checked", selectedValues.contains(value));
			row.put("value", value);
			row.put("frequency", frequency);
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/setDataSourceSubsetColumn1SelectedValues")
	@Transactional
	@ResponseBody
	public Map<String, Object> setDataSourceSubsetColumn1SelectedValues
	(
			@RequestParam(value = "dataSourceId") Long dataSourceId,
			@RequestParam(value = "value", required = true) String value,
			@RequestParam(value = "selected", required = true) boolean selected
	)
	{
		// get dataSource
		
		DataSource dataSource = dataSourceRepository.getOne(dataSourceId);
		
		// set subsetColumnSelectedValues
		
		if (StringUtils.isEmpty(value))
		{
			if (selected)
			{
				// add all values
				
				dataSource.setSubsetColumn1SelectedValues(dataSource.getSubsetColumn1ValueFrequencies().keySet().toArray(new String[] {}));
				
			}
			else
			{
				// remove all values
				
				dataSource.setSubsetColumn1SelectedValues(new String[] {});
				
			}
			
		}
		else
		{
			// get current selected values
			
			String[] selectedValues = dataSource.getSubsetColumn1SelectedValues();
			
			// modify selected values
			
			if (selected)
			{
				// add value
				
				selectedValues = ArrayUtils.add(selectedValues, value);
				
			}
			else
			{
				// remove value
				
				selectedValues = ArrayUtils.removeAllOccurences(selectedValues, value);
				
			}
			
			dataSource.setSubsetColumn1SelectedValues(selectedValues);
			
		}
		
		dataSourceRepository.saveAndFlush(dataSource);
		dataSourceRepository.refresh(dataSource);
		
		// update subset based values
		
		updateSubsetBasedValues(dataSource);
		
		// return update
		
		return getDataSourceSubsetCounts(dataSource);
		
	}
	
	@RequestMapping(value = "/getDataSourceSubsetColumn2Values")
	@ResponseBody
	public Map<String, Object> getDataSourceSubsetColumn2Values
	(
			@RequestParam(value = "dataSourceId", required = false) Long dataSourceId
	)
	{
		Map<String, Object> output = new HashMap<>();
		
		// skip empty requests
		
		if (dataSourceId == null)
		{
			output.put("total", 0);
			output.put("rows", new ArrayList<>());
			
			return output;
			
		}
		
		// get dataSource
		
		Optional<DataSource> optionalDataSource = dataSourceRepository.findById(dataSourceId);
		
		if (!optionalDataSource.isPresent())
		{
			throw new ApplicationException("Data source is not found with given id: " + dataSourceId + ".");
			
		}
		
		DataSource dataSource = optionalDataSource.get();
		
		// populate output
		
		List<Map<String, Object>> rows = new ArrayList<>();
		output.put("rows", rows);
		
		Set<String> selectedValues = new HashSet<String>(Arrays.asList(dataSource.getSubsetColumn2SelectedValues()));
		
		List<Map.Entry<String, Long>> valueFrequencies = new ArrayList<Map.Entry<String, Long>>(dataSource.getSubsetColumn2ValueFrequencies().entrySet());
		output.put("total", valueFrequencies.size());
		
		for (Map.Entry<String, Long> valueFrequencyEntry : valueFrequencies)
		{
			String value = valueFrequencyEntry.getKey();
			Long frequency = valueFrequencyEntry.getValue();
			
			Map<String, Object> row = new HashMap<>();
			rows.add(row);
			
			row.put("checked", selectedValues.contains(value));
			row.put("value", value);
			row.put("frequency", frequency);
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/setDataSourceSubsetColumn2SelectedValues")
	@Transactional
	@ResponseBody
	public Map<String, Object> setDataSourceSubsetColumn2SelectedValues
	(
			@RequestParam(value = "dataSourceId") Long dataSourceId,
			@RequestParam(value = "value", required = true) String value,
			@RequestParam(value = "selected", required = true) boolean selected
	)
	{
		// get dataSource
		
		DataSource dataSource = dataSourceRepository.getOne(dataSourceId);
		
		// set subsetColumnSelectedValues
		
		if (StringUtils.isEmpty(value))
		{
			if (selected)
			{
				// add all values
				
				dataSource.setSubsetColumn2SelectedValues(dataSource.getSubsetColumn2ValueFrequencies().keySet().toArray(new String[] {}));
				
			}
			else
			{
				// remove all values
				
				dataSource.setSubsetColumn2SelectedValues(new String[] {});
				
			}
			
		}
		else
		{
			// get current selected values
			
			String[] selectedValues = dataSource.getSubsetColumn2SelectedValues();
			
			// modify selected values
			
			if (selected)
			{
				// add value
				
				selectedValues = ArrayUtils.add(selectedValues, value);
				
			}
			else
			{
				// remove value
				
				selectedValues = ArrayUtils.removeAllOccurences(selectedValues, value);
				
			}
			
			dataSource.setSubsetColumn2SelectedValues(selectedValues);
			
		}
		
		dataSourceRepository.saveAndFlush(dataSource);
		dataSourceRepository.refresh(dataSource);
		
		// update subset based values
		
		updateSubsetBasedValues(dataSource);
		
		// return update
		
		return getDataSourceSubsetCounts(dataSource);
		
	}
	
	@RequestMapping(value = "/getDataSourceGlobalVariableColumnNameValid")
	public Map<String, Object> getDataSourceGlobalVariableColumnNameValid
	(
			@RequestParam(value = "dataSourceId") Long dataSourceId,
			@RequestParam(value = "globalVariable") String globalVariable,
			@RequestParam(value = "columnName") String columnName
	)
	{
		// get dataSource
		
		DataSource dataSource = dataSourceRepository.getOne(dataSourceId);
		
		// get global variable column name valid
		
		boolean valid = true;
		String message = null;
		
		switch (globalVariable)
		{
		case DATA_SOURCE_GLOBAL_VARIABLE_FACILITY_TYPE:
			
			// check FacilityType and HealthSector use different columns
			
			if (StringUtils.isNotEmpty(dataSource.getHealthSectorColumnName()) && dataSource.getHealthSectorColumnName().equals(columnName))
			{
				valid = false;
				message = "Facility Type and Health Sector cannot use same column name from same data source.";
				
			}
			
			break;
			
		case DATA_SOURCE_GLOBAL_VARIABLE_HEALTH_SECTOR:
			
			// check FacilityType and HealthSector use different columns
			
			if (StringUtils.isNotEmpty(dataSource.getFacilityTypeColumnName()) && dataSource.getFacilityTypeColumnName().equals(columnName))
			{
				valid = false;
				message = "Facility Type and Health Sector cannot use same column name from same data source.";
				
			}
			
			break;
			
		default:
			
		}
		
		Map<String, Object> output = new HashMap<>();
		
		output.put("valid", valid);
		output.put("message", message);
		
		return output;
		
	}
	
	@RequestMapping(value = "/setDataSourceGlobalVariableColumnName")
	@Transactional
	public void setDataSourceGlobalVariableColumnName
	(
			@RequestParam(value = "dataSourceId") Long dataSourceId,
			@RequestParam(value = "globalVariable") String globalVariable,
			@RequestParam(value = "columnName") String columnName
	)
	{
		// get dataSource
		
		DataSource dataSource = dataSourceRepository.getOne(dataSourceId);
		
		// set global variable column name
		
		switch (globalVariable)
		{
		case DATA_SOURCE_GLOBAL_VARIABLE_FACILITY_TYPE:
			
			// check FacilityType and HealthSector use different columns
			
			if (StringUtils.isNotEmpty(dataSource.getHealthSectorColumnName()) && dataSource.getHealthSectorColumnName().equals(columnName))
			{
				throw new ApplicationException("Facility Type and Health Sector cannot use same column name from same data source.");
				
			}
			
			// set columnName
			
			dataSource.setFacilityTypeColumnName(columnName);
			
			break;
			
		case DATA_SOURCE_GLOBAL_VARIABLE_HEALTH_SECTOR:
			
			// check FacilityType and HealthSector use different columns
			
			if (StringUtils.isNotEmpty(dataSource.getFacilityTypeColumnName()) && dataSource.getFacilityTypeColumnName().equals(columnName))
			{
				throw new ApplicationException("Facility Type and Health Sector cannot use same column name from same data source.");
				
			}
			
			// set columnName
			
			dataSource.setHealthSectorColumnName(columnName);
			
			break;
			
		case DATA_SOURCE_GLOBAL_VARIABLE_SUBNATIONAL_UNIT:
			
			dataSource.setSubnationalUnitColumnName(columnName);
			
			break;
			
		default:
			throw new ApplicationException("Unknown global variable: " + globalVariable + ".");
			
		}
		
		// extract column values
		
		Map<String, Long> valueFrequencies = extractDataSouceColumnValueFrequencies(dataSource, columnName, true);
		
		// set global variable column values
		
		switch (globalVariable)
		{
		case DATA_SOURCE_GLOBAL_VARIABLE_FACILITY_TYPE:
			
			// set values and valueFrequencies
			
			dataSource.setFacilityTypeValues(valueFrequencies.keySet().toArray(new String[] {}));
			dataSource.setFacilityTypeValueFrequencies(valueFrequencies);
			
			break;
			
		case DATA_SOURCE_GLOBAL_VARIABLE_HEALTH_SECTOR:
			
			// set values and valueFrequencies
			
			dataSource.setHealthSectorValues(valueFrequencies.keySet().toArray(new String[] {}));
			dataSource.setHealthSectorValueFrequencies(valueFrequencies);
			
			break;
			
		case DATA_SOURCE_GLOBAL_VARIABLE_SUBNATIONAL_UNIT:
			
			// set values and valueFrequencies
			
			dataSource.setSubnationalUnitValueFrequencies(valueFrequencies);
			
			// clear existing subnationalUnitMappings
			
			for (SubnationalUnitMapping subnationalUnitMapping : new HashSet<SubnationalUnitMapping>(dataSource.getSubnationalUnitMappings()))
			{
				dataSource.removeSubnationalUnitMapping(subnationalUnitMapping);
				
			}
			
			break;
			
		default:
			throw new ApplicationException("Unknown global variable: " + globalVariable + ".");
			
		}
		
		// HealthSector and FacilityType combinations
		
		if (DATA_SOURCE_GLOBAL_VARIABLE_FACILITY_TYPE.equals(globalVariable) || DATA_SOURCE_GLOBAL_VARIABLE_HEALTH_SECTOR.equals(globalVariable))
		{
			// generate ppaSectorMappingValueCombinationFrequencies
			
			dataSource.setPpaSectorMappingValueCombinationFrequencies
			(
					extractDataSouceColumnValueCombinationFrequencies
					(
							dataSource,
							new String[] {dataSource.getHealthSectorColumnName(), dataSource.getFacilityTypeColumnName(), },
							true
					)
			)
			;
			
			// clear existing ppaSectorMappings
			
			for (PpaSectorMapping ppaSectorMapping : new HashSet<PpaSectorMapping>(dataSource.getPpaSectorMappings()))
			{
				dataSource.removePpaSectorMapping(ppaSectorMapping);
				
			}
			
		}
		
	}
	
	@RequestMapping(value = "/getMetrics")
	@ResponseBody
	public List<Map<String, Object>> getMetrics
	(
			@RequestParam(value = "columnValueFilter", required = false) Boolean columnValueFilter,
			@RequestParam(value = "selected", required = false) Boolean selected,
			@RequestParam(value = "dataSourceAssigned", required = false) Boolean dataSourceAssigned
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// build output
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (Metric metric : selectedPpa.getMetrics())
		{
			if
			(
					// columnValueFilter
					(columnValueFilter == null || metric.getMetricType().getColumnValueFilter() == columnValueFilter.booleanValue())
					&&
					// selected
					(selected == null || metric.getSelected() == selected.booleanValue())
					&&
					// dataSourceAssigned
					(dataSourceAssigned == null || (metric.getDataSource() != null) == dataSourceAssigned)
			)
			{
				Map<String, Object> outputRow = new HashMap<>();
				output.add(outputRow);
				
				outputRow.put("id", metric.getId());
				outputRow.put("metricId", metric.getId());
				outputRow.put("required", metric.getMetricType().getRequired());
				outputRow.put("metricName", metric.getMetricType().getName());
				outputRow.put("selected", metric.getSelected());
				outputRow.put("dataPointName", metric.getDataPointName());
				outputRow.put("fileUpload", "");
				outputRow.put("fileUploadButton", "");
				outputRow.put("dataSourceId", (metric.getDataSource() == null ? "" : metric.getDataSource().getId().toString()));
				outputRow.put("userFileId", (metric.getDataSource() == null ? "" : metric.getDataSource().getUserFile().getId().toString()));
				outputRow.put("userFileName", (metric.getDataSource() == null ? "" : metric.getDataSource().getUserFile().getFileName().toString()));
				outputRow.put("dataSourceColumnName", metric.getDataSourceColumnName());
				
				// value count
				
				long valueCount = 0;
				
				Set<String> selectedColumnValues = new HashSet<>(Arrays.asList(metric.getSelectedColumnValues()));
				
				for (Map.Entry<String, Long> columnValueFrequencyEntry : metric.getColumnValueFrequencies().entrySet())
				{
					String value = columnValueFrequencyEntry.getKey();
					Long frequency = columnValueFrequencyEntry.getValue();
					
					if (selectedColumnValues.contains(value))
					{
						valueCount += frequency.longValue(); 
						
					}
					
				}
				
				outputRow.put("valueCount", valueCount);
				
			}
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/setMetricSelected")
	@Transactional
	@ResponseBody
	public void setMetricSelected
	(
			@RequestParam(value = "metricId", required = false) Long metricId,
			@RequestParam(value = "selected") boolean selected
	)
	{
		// all PPA metrics
		if (metricId == null)
		{
			Ppa ppa = getSelectedPpa(true);
			
			for (Metric ppaMetric : ppa.getMetrics())
			{
				ppaMetric.setSelected(selected);
				
			}
			
		}
		// given PPA metric
		else
		{
			Optional<Metric> optionalPpaMetric = metricRepository.findById(metricId);
			
			if (!optionalPpaMetric.isPresent())
			{
				throw new ApplicationException("PPA metric is not found with given id: " + metricId + ".");
				
			}
			
			Metric ppaMetric = optionalPpaMetric.get();
			
			ppaMetric.setSelected(selected);
			
		}
		
	}
	
	@RequestMapping(value = "/setMetricDataPointName")
	@Transactional
	@ResponseBody
	public void setMetricDataPointName
	(
			@RequestParam(value = "metricId") Long metricId,
			@RequestParam(value = "dataPointName") String dataPointName
	)
	{
		Optional<Metric> optionalPpaMetric = metricRepository.findById(metricId);
		
		if (!optionalPpaMetric.isPresent())
		{
			throw new ApplicationException("PPA metric is not found with given id: " + metricId + ".");
			
		}
		
		Metric ppaMetric = optionalPpaMetric.get();
		
		ppaMetric.setDataPointName(dataPointName);
		
	}
	
	@RequestMapping(value = "/setMetricUserFile")
	@Transactional
	public void setMetricUserFile
	(
			@RequestParam(value = "metricId") Long metricId,
			@RequestParam(value = "userFileId", required = false) Long userFileId
	)
	{
		// get PPA
		
		Ppa ppa = getSelectedPpa(true);
		
		// get metric
		
		Metric metric = getMetric(metricId);
		
		// get userFile
		
		UserFile userFile = getUserFile(userFileId);
		
		// get existing dataSource for this PPA userFile
		
		DataSource dataSource = getPpaUserFileDataSource(ppa.getId(), userFileId);
		
		// create dataSource if not exists
		
		if (dataSource == null)
		{
			dataSource = new DataSource();
			ppa.addDataSource(dataSource);
			userFile.addDataSource(dataSource);
			
			dataSourceRepository.flush();;
			ppaRepository.flush();
			userFileRepository.flush();
			
			dataSourceRepository.refresh(dataSource);
			
		}
		
		// set metric dataSource
		
		metric.setDataSource(dataSource);
		
	}
	
	@RequestMapping(value = "/getDataSourceColumnNames")
	@ResponseBody
	public List<Map<String, Object>> getDataSourceColumnNames
	(
			@RequestParam(value = "dataSourceId", required = false) Long dataSourceId
	)
	{
		// skip empty requests
		
		if (dataSourceId == null)
		{
			return new ArrayList<>();
			
		}
		
		// get dataSource
		
		DataSource dataSource = getDataSource(dataSourceId);
		
		// populate output
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (String columnName : dataSource.getUserFile().getColumnNames())
		{
			Map<String, Object> outputRow = new HashMap<>();
			output.add(outputRow);
			
			outputRow.put("value", columnName);
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/getGlobalVariableDataSources")
	@ResponseBody
	public List<Map<String, Object>> getGlobalVariableDataSources
	(
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// get PPA associated dataSources
		
		Set<DataSource> associatedDataSources = getPpaAssociatedDataSources(selectedPpa);
		
		// populate output
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (DataSource dataSource : associatedDataSources)
		{
			// FacilityType
			
			Map<String, Object> facilityTypeOutputRow = new HashMap<>();
			output.add(facilityTypeOutputRow);
			
			facilityTypeOutputRow.put("dataSourceId", dataSource.getId());
			facilityTypeOutputRow.put("globalVariable", DATA_SOURCE_GLOBAL_VARIABLE_FACILITY_TYPE);
			facilityTypeOutputRow.put("globalVariableName", DATA_SOURCE_GLOBAL_VARIABLE_FACILITY_TYPE_NAME);
			facilityTypeOutputRow.put("dataSourceFileName", dataSource.getUserFile().getFileName());
			facilityTypeOutputRow.put("globalVariableColumnName", dataSource.getFacilityTypeColumnName());
			
			// HealthSector
			
			Map<String, Object> healthSectorOutputRow = new HashMap<>();
			output.add(healthSectorOutputRow);
			
			healthSectorOutputRow.put("dataSourceId", dataSource.getId());
			healthSectorOutputRow.put("globalVariable", DATA_SOURCE_GLOBAL_VARIABLE_HEALTH_SECTOR);
			healthSectorOutputRow.put("globalVariableName", DATA_SOURCE_GLOBAL_VARIABLE_HEALTH_SECTOR_NAME);
			healthSectorOutputRow.put("dataSourceFileName", dataSource.getUserFile().getFileName());
			healthSectorOutputRow.put("globalVariableColumnName", dataSource.getHealthSectorColumnName());
			
			// SubnationalUnit
			
			if (!PPA_AGGREGATION_LEVEL_NATIONAL.equals(selectedPpa.getAggregationLevel()))
			{
				Map<String, Object> subnationalUnitOutputRow = new HashMap<>();
				output.add(subnationalUnitOutputRow);
				
				subnationalUnitOutputRow.put("dataSourceId", dataSource.getId());
				subnationalUnitOutputRow.put("globalVariable", DATA_SOURCE_GLOBAL_VARIABLE_SUBNATIONAL_UNIT);
				subnationalUnitOutputRow.put("globalVariableName", selectedPpa.getAggregationLevel());
				subnationalUnitOutputRow.put("dataSourceFileName", dataSource.getUserFile().getFileName());
				subnationalUnitOutputRow.put("globalVariableColumnName", dataSource.getSubnationalUnitColumnName());
				
			}
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/getGlobalVariableDataSourceColumnValues")
	@ResponseBody
	public List<Map<String, Object>> getGlobalVariableDataSourceColumnValues
	(
			@RequestParam(value = "dataSourceId", required = false) Long dataSourceId,
			@RequestParam(value = "globalVariable", required = false) String globalVariable
	)
	{
		// skip empty requests
		
		if (dataSourceId == null || globalVariable == null)
		{
			return new ArrayList<>();
			
		}
		
		// get dataSource
		
		DataSource dataSource = getDataSource(dataSourceId);
		
		// get value frequencies
		
		Map<String, Long> valueFrequencies;
		
		switch (globalVariable)
		{
		case DATA_SOURCE_GLOBAL_VARIABLE_FACILITY_TYPE:
			valueFrequencies = dataSource.getFacilityTypeValueFrequencies();
			break;
			
		case DATA_SOURCE_GLOBAL_VARIABLE_HEALTH_SECTOR:
			valueFrequencies = dataSource.getHealthSectorValueFrequencies();
			break;
			
		case DATA_SOURCE_GLOBAL_VARIABLE_SUBNATIONAL_UNIT:
			valueFrequencies = dataSource.getSubnationalUnitValueFrequencies();
			break;
			
		default:
			throw new ApplicationException("Unknown global variable: " + globalVariable + ".");
			
		}
		
		// build output
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (Map.Entry<String, Long> valueFrequencyEntry : valueFrequencies.entrySet())
		{
			String value = valueFrequencyEntry.getKey();
			Long frequency = valueFrequencyEntry.getValue();
			
			Map<String, Object> columnValueRow = new HashMap<>();
			output.add(columnValueRow);
			
			columnValueRow.put("value", value);
			columnValueRow.put("count", frequency);
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/setMetricDataSourceColumnName")
	@Transactional
	@ResponseBody
	public void setMetricDataSourceColumnName
	(
			@RequestParam(value = "metricId") Long metricId,
			@RequestParam(value = "dataSourceColumnName") String dataSourceColumnName
	)
	{
		// get metric
		
		Metric metric = getMetric(metricId);
		
		// assert dataSource assigned
		
		if (metric.getDataSource() == null)
		{
			throw new ApplicationException("Cannot set metric column name since it doesn't have data source assigned.");
			
		}
		
		// set dataSourceColumnName
		
		metric.setDataSourceColumnName(dataSourceColumnName);
		
		// columnValueFrequencies
		
		Map<String, Long> valueFrequencies = extractDataSouceColumnValueFrequencies(metric.getDataSource(), dataSourceColumnName, true);
		
		metric.setColumnValueFrequencies(valueFrequencies);
		
		// clear selectedColumnValues
		
		metric.setSelectedColumnValues(new String[] {});
		
	}
	
	@RequestMapping(value = "/getMetricColumnValues")
	@ResponseBody
	public List<Map<String, Object>> getMetricColumnValues
	(
			@RequestParam(value = "metricId", required = false) Long metricId
	)
	{
		// skip empty requests
		
		if (metricId == null)
		{
			return new ArrayList<>();
			
		}
		
		// get metric
		
		Metric metric = metricRepository.getOne(metricId);
		
		// get selected column values
		
		Set<String> selectedColumnValues = new HashSet<>(Arrays.asList(metric.getSelectedColumnValues()));
		
		// populate column values
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (Map.Entry<String, Long> columnValueFrequencyEntry : metric.getColumnValueFrequencies().entrySet())
		{
			String value = columnValueFrequencyEntry.getKey();
			Long frequency = columnValueFrequencyEntry.getValue();
			
			Map<String, Object> columnValueRow = new HashMap<>();
			output.add(columnValueRow);
			
			columnValueRow.put("value", value);
			columnValueRow.put("count", frequency);
			
			if (selectedColumnValues.contains(value))
			{
				columnValueRow.put("checked", Boolean.TRUE);
				
			}
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/setMetricSelectedColumnValues")
	@Transactional
	@ResponseBody
	public void setMetricSelectedColumnValues
	(
			@RequestParam(value = "metricId") Long metricId,
			@RequestParam(value = "selectedColumnValues[]", required = false) String[] selectedColumnValues
	)
	{
		// convert null array to empty array
		
		if (selectedColumnValues == null)
		{
			selectedColumnValues = new String[] {};
			
		}
		
		// get metric
		
		Metric metric = metricRepository.getOne(metricId);
		
		// set selectedColumnValues
		
		metric.setSelectedColumnValues(selectedColumnValues);
		
	}
	
	@RequestMapping(value = "/getPpaSectors")
	@ResponseBody
	public List<Map<String, Object>> getPpaSectors
	(
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// populate output
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (PpaSector ppaSector : selectedPpa.getPpaSectors())
		{
			Map<String, Object> outputRow = new HashMap<>();
			output.add(outputRow);
			
			outputRow.put("id", ppaSector.getId());
			outputRow.put("name", ppaSector.getName());
			outputRow.put("level0", "0");
			outputRow.put("level1", "1");
			outputRow.put("level2", "2");
			outputRow.put("level3", "3");
			outputRow.put("level4", "4");
			outputRow.put("level5", "5");
			outputRow.put("level6", "6");
			outputRow.put("levelOther", "other");
			outputRow.put("editable", ppaSector.getEditable());
			outputRow.put("selected", ppaSector.getSelected());
			
			List<String> levels = new ArrayList<>();
			
			for (PpaSectorLevel ppaSectorLevel : ppaSector.getPpaSectorLevels())
			{
				levels.add(ppaSectorLevel.getLevel());
				
			}
			
			outputRow.put("levels", levels);
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/deletePpaSectors")
	@ResponseBody
	@Transactional
	public void deletePpaSectors
	(
			@RequestParam(value = "ppaSectorIds[]") List<Long> ppaSectorIds
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// get ppaSectors
		
		List<PpaSector> ppaSectors = ppaSectorRepository.findByIdIn(ppaSectorIds);
		
		// update database
		
		for (PpaSector ppaSector : ppaSectors)
		{
			selectedPpa.removePpaSector(ppaSector);
			
		}

	}

	@RequestMapping(value = "/setPpaSectorSelected")
	@Transactional
	@ResponseBody
	public void setPpaSectorSelected
	(
			@RequestParam(value = "id") Long id,
			@RequestParam(value = "selected") boolean selected
	)
	{
		PpaSector ppaSector = ppaSectorRepository.getOne(id);
		
		ppaSector.setSelected(selected);
		
	}
	
	@RequestMapping(value = "/setPpaSectorName")
	@Transactional
	@ResponseBody
	public void setPpaSectorName
	(
			@RequestParam(value = "id") Long id,
			@RequestParam(value = "name") String name
	)
	{
		PpaSector ppaSector = ppaSectorRepository.getOne(id);
		
		ppaSector.setName(name);
		
	}
	
	@RequestMapping(value = "/getPpaSectorLevels")
	@ResponseBody
	public List<Map<String, Object>> getPpaSectorLevels
	(
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// populate output
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (PpaSector ppaSector : selectedPpa.getPpaSectors())
		{
			for (PpaSectorLevel ppaSectorLevel : ppaSector.getPpaSectorLevels())
			{
				Map<String, Object> outputRow = new HashMap<>();
				output.add(outputRow);
				
				outputRow.put("ppaSectorId", ppaSector.getId());
				outputRow.put("ppaSectorName", ppaSector.getName());
				outputRow.put("ppaSectorLevelId", ppaSectorLevel.getId());
				outputRow.put("ppaSectorLevel", ppaSectorLevel.getLevel());
				outputRow.put("text", buildPpaSectorLevelText(ppaSector.getName(), ppaSectorLevel.getLevel()));
				
			}
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/setPpaSectorLevel")
	@Transactional
	@ResponseBody
	public void setPpaSectorLevel
	(
			@RequestParam(value = "ppaSectorId") Long ppaSectorId,
			@RequestParam(value = "level") String level,
			@RequestParam(value = "selected") boolean selected
	)
	{
		Optional<PpaSector> optionalPpaSector = ppaSectorRepository.findById(ppaSectorId);
		
		if (!optionalPpaSector.isPresent())
		{
			throw new ApplicationException("Cannot find ppaSector with id=" + ppaSectorId + ".");
			
		}
		
		PpaSector ppaSector = optionalPpaSector.get();
		
		Optional<PpaSectorLevel> optionalPpaSectorLevel = ppaSectorLevelRepository.findByPpaSectorIdAndLevel(ppaSectorId, level);
		
		if (selected)
		{
			if (!optionalPpaSectorLevel.isPresent())
			{
				PpaSectorLevel ppaSectorLevel = new PpaSectorLevel();
				ppaSectorLevel.setLevel(level);
				
				ppaSector.addPpaSectorLevel(ppaSectorLevel);
				
			}
			
		}
		else
		{
			if (optionalPpaSectorLevel.isPresent())
			{
				PpaSectorLevel ppaSectorLevel = optionalPpaSectorLevel.get();
				
				ppaSector.removePpaSectorLevel(ppaSectorLevel);
				
			}
			
		}
		
	}
	
	@RequestMapping(value = "/getDataSourcePpaSectorMappings")
	@ResponseBody
	public Map<String, Object> getDataSourcePpaSectorMappings
	(
			@RequestParam(value = "dataSourceId", required = false) Long dataSourceId,
			@RequestParam(value = "rows", required = false) Integer rows,
			@RequestParam(value = "page", required = false) Integer page
	)
	{
		// skip empty request
		
		if (dataSourceId == null)
		{
			Map<String, Object> output = new HashMap<>();
			
			output.put("total", 0);
			output.put("rows", new ArrayList<>());
			
			return output;
			
		}
		
		// get dataSource
		
		DataSource dataSource = dataSourceRepository.getOne(dataSourceId);
		
		// get existing ppaSectorMappings
		
		Map<String, PpaSectorMapping> ppaSectorMappings = new HashMap<>();
		
		for (PpaSectorMapping ppaSectorMapping : dataSource.getPpaSectorMappings())
		{
			ppaSectorMappings.put(ppaSectorMapping.getValueCombination(), ppaSectorMapping);
			
		}
		
		Map<String, Long> ppaSectorMappingValueCombinationFrequencies = dataSource.getPpaSectorMappingValueCombinationFrequencies();
		
		long skip;
		int limit;
		if (rows != null && page != null)
		{
			skip = rows.longValue() * (page.longValue() - 1);
			limit = rows.intValue();
			
		}
		else
		{
			skip = 0L;
			limit = ppaSectorMappingValueCombinationFrequencies.size();
			
		}
		
		// populate output
		
		Map<String, Object> output = new HashMap<>();
		
		output.put("total", ppaSectorMappingValueCombinationFrequencies.size());
		
		List<Map<String, Object>> outputRows = new ArrayList<>();
		output.put("rows", outputRows);
		
		for (Map.Entry<String, Long> valueCombinationFrequencyEntry : ppaSectorMappingValueCombinationFrequencies.entrySet().stream().sorted(mapEntryKeyComparator).skip(skip).limit(limit).collect(Collectors.toList()))
		{
			String valueCombination = valueCombinationFrequencyEntry.getKey();
			Long valueCombinationFrequency = valueCombinationFrequencyEntry.getValue();
			
			Map<String, Object> outputRow = new HashMap<>();
			outputRows.add(outputRow);
			
			outputRow.put("dataSourceId", dataSourceId);
			outputRow.put("valueCombination", valueCombination);
			outputRow.put("valueCombinationFrequency", valueCombinationFrequency);
			
			String[] valueCombinationTokens = Common.unpackTokens(valueCombination);
			outputRow.put("healthSector", valueCombinationTokens[0]);
			try
			{
				outputRow.put("facilityType", valueCombinationTokens[1]);
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}
			
			outputRow.put("ppaSectorLevelId", (ppaSectorMappings.containsKey(valueCombination) ? ppaSectorMappings.get(valueCombination).getPpaSectorLevel().getId() : ""));
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/getAllPpaSectorLevelMapped")
	@ResponseBody
	public Map<String, Object> getAllPpaSectorLevelMapped
	(
	)
	{
		// get selected ppa
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// return value
		
		boolean allPpaSectorLevelMapped = true;
		
		// collect used dataSources
		
		Set<DataSource> dataSources = new HashSet<>();
		
		for (Metric metric : selectedPpa.getMetrics())
		{
			// selected metrics only
			
			if (!metric.getSelected())
				continue;
			
			// metric with assigned dataSource only
			
			if (metric.getDataSource() == null)
				continue;
			
			// get dataSource
			
			dataSources.add(metric.getDataSource());
			
		}
		
		for (DataSource dataSource : dataSources)
		{
			// check if all aggregation levels are mapped
			
			Set<String> mappedValueCombinations = new HashSet<>();
			for (PpaSectorMapping ppaSectorMapping : dataSource.getPpaSectorMappings())
			{
				mappedValueCombinations.add(ppaSectorMapping.getValueCombination());
				
			}
			
			if (!mappedValueCombinations.containsAll(dataSource.getPpaSectorMappingValueCombinationFrequencies().keySet()))
			{
				allPpaSectorLevelMapped = false;
				
				break;
				
			}
			
		}
		
		// build and return output
		
		return ImmutableMap.of("value", Boolean.valueOf(allPpaSectorLevelMapped));
		
	}
	
	@RequestMapping(value = "/setDataSourcePpaSectorMapping")
	@Transactional
	@ResponseBody
	public Map<String, Object> setDataSourcePpaSectorMapping
	(
			@RequestParam(value = "dataSourceId") Long dataSourceId,
			@RequestParam(value = "valueCombination") String valueCombination,
			@RequestParam(value = "ppaSectorLevelId") Long ppaSectorLevelId
	)
	{
		// get dataSource
		
		Optional<DataSource> optionalDataSource = dataSourceRepository.findById(dataSourceId);
		
		if (!optionalDataSource.isPresent())
		{
			throw new ApplicationException("Cannot find dataSource with id=" + dataSourceId + ".");
			
		}
		
		DataSource dataSource = optionalDataSource.get();
		
		// get ppaSectorLevel
		
		Optional<PpaSectorLevel> optionalPpaSectorLevel = ppaSectorLevelRepository.findById(ppaSectorLevelId);
		
		if (!optionalPpaSectorLevel.isPresent())
		{
			throw new ApplicationException("Cannot find ppaSectorLevel with id=" + ppaSectorLevelId + ".");
			
		}
		
		PpaSectorLevel ppaSectorLevel = optionalPpaSectorLevel.get();
		
		// get ppaSectorMapping
		
		Optional<PpaSectorMapping> optionalPpaSectorMapping = ppaSectorMappingRepository.findByDataSourceIdAndValueCombination(dataSourceId, valueCombination);
		
		// delete old mapping
		
		if (optionalPpaSectorMapping.isPresent())
		{
			PpaSectorMapping ppaSectorMapping = optionalPpaSectorMapping.get();
			
			ppaSectorMapping.getDataSource().removePpaSectorMapping(ppaSectorMapping);
			ppaSectorMapping.getPpaSectorLevel().removePpaSectorMapping(ppaSectorMapping);
			
			ppaSectorMappingRepository.flush();
			
		}
		
		PpaSectorMapping ppaSectorMapping = new PpaSectorMapping();
		
		ppaSectorMapping.setValueCombination(valueCombination);
		dataSource.addPpaSectorMapping(ppaSectorMapping);
		ppaSectorLevel.addPpaSectorMapping(ppaSectorMapping);
		
		// return response
		
		return ImmutableMap.of("mapped", isDataSourceAllPpaSectorLevelsMapped(dataSource));
		
	}
	
	@RequestMapping(value = "/getSubnationalUnits")
	@ResponseBody
	public List<Map<String, Object>> getSubnationalUnits
	(
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// get subnationalUnits
		
		Set<SubnationalUnit> subnationalUnits = selectedPpa.getSubnationalUnits();
		
		// populate output
		
		List<Map<String, Object>> output = new ArrayList<>();
		
		for (SubnationalUnit subnationalUnit : subnationalUnits)
		{
			Map<String, Object> outputRow = new HashMap<>();
			output.add(outputRow);
			
			outputRow.put("id", subnationalUnit.getId());
			outputRow.put("name", subnationalUnit.getName());
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/populateSubnationalUnits")
	@Transactional
	@ResponseBody
	public void populateSubnationalUnits
	(
			@RequestParam(value = "dataSourceId") Long dataSourceId
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// get dataSource
		
		DataSource dataSource = getDataSource(dataSourceId);
		
		// delete existing subnationalUnits
		
		for (SubnationalUnit subnationalUnit : new ArrayList<>(selectedPpa.getSubnationalUnits()))
		{
			selectedPpa.removeSubnationalUnit(subnationalUnit);
			
		}
		
		userRepository.flush();
		
		// create subnationalUnits
		
		if (dataSource.getSubnationalUnitValueFrequencies().size() == 0)
		{
			throw new ApplicationException(selectedPpa.getAggregationLevel() + " column doesn't have any values in dataSource: " + dataSource.getUserFile().getFileName() + ".");
			
		}
		
		for (String subnationalUnitValue : dataSource.getSubnationalUnitValueFrequencies().keySet())
		{
			SubnationalUnit subnationalUnit = new SubnationalUnit();
			selectedPpa.addSubnationalUnit(subnationalUnit);
			
			subnationalUnit.setName(subnationalUnitValue);
			
		}
		
		subnationalUnitRepository.flush();
		
		// set up mapping for master dataSource
		
		for (String dataSourceSubnationalUnitColumnValue : dataSource.getSubnationalUnitValueFrequencies().keySet())
		{
			for (SubnationalUnit subnationalUnit : selectedPpa.getSubnationalUnits())
			{
				// compare ignoring case
				
				if (subnationalUnit.getName().equalsIgnoreCase(dataSourceSubnationalUnitColumnValue))
				{
					setDataSourceSubnationalUnitMapping(dataSourceId, dataSourceSubnationalUnitColumnValue, subnationalUnit.getId());
					
				}
				
			}
			
		}
		
		// set up mapping for other dataSources
		
		for (DataSource otherDataSource : selectedPpa.getDataSources())
		{
			// skip master dataSource
			
			if (otherDataSource.getId().longValue() == dataSourceId.longValue())
				continue;
			
			// skip dataSource without subnationalUnitColumnName set
			
			if (StringUtils.isEmpty(otherDataSource.getSubnationalUnitColumnName()))
				continue;
			
			for (String otherDataSourceSubnationalUnitColumnValue : otherDataSource.getSubnationalUnitValueFrequencies().keySet())
			{
				for (SubnationalUnit subnationalUnit : selectedPpa.getSubnationalUnits())
				{
					// compare ignoring case
					
					if (subnationalUnit.getName().equalsIgnoreCase(otherDataSourceSubnationalUnitColumnValue))
					{
						setDataSourceSubnationalUnitMapping(otherDataSource.getId(), otherDataSourceSubnationalUnitColumnValue, subnationalUnit.getId());
						
					}
					
				}
				
			}
			
			
		}
		
	}
	
	@RequestMapping(value = "/createSubnationalUnit")
	@Transactional
	@ResponseBody
	public void createSubnationalUnit
	(
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// create subnationalUnit
		
		SubnationalUnit subnationalUnit = new SubnationalUnit();
		selectedPpa.addSubnationalUnit(subnationalUnit);
		
	}
	
	@RequestMapping(value = "/deleteSubnationalUnits")
	@ResponseBody
	@Transactional
	public void deleteSubnationalUnits
	(
			@RequestParam(value = "subnationalUnitIds[]") List<Long> subnationalUnitIds
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// get subnationalUnits
		
		List<SubnationalUnit> subnationalUnits = subnationalUnitRepository.findByIdIn(subnationalUnitIds);
		
		// update database
		
		for (SubnationalUnit subnationalUnit : subnationalUnits)
		{
			selectedPpa.removeSubnationalUnit(subnationalUnit);
			
		}

	}

	@RequestMapping(value = "/setSubnationalUnitName")
	@Transactional
	@ResponseBody
	public void setSubnationalUnitName
	(
			@RequestParam(value = "subnationalUnitId") Long subnationalUnitId,
			@RequestParam(value = "subnationalUnitName") String subnationalUnitName
	)
	{
		// get subnationalUnit
		
		Optional<SubnationalUnit> optionalSubnationalUnit = subnationalUnitRepository.findById(subnationalUnitId);
		
		if (!optionalSubnationalUnit.isPresent())
		{
			throw new ApplicationException("Cannot find subnationalUnit with id=" + subnationalUnitId + ".");
			
		}
		
		SubnationalUnit subnationalUnit = optionalSubnationalUnit.get();
		
		// set nema
		
		subnationalUnit.setName(subnationalUnitName);
		
	}
	
	@RequestMapping(value = "/getDataSourceSubnationalUnitMappings")
	@ResponseBody
	public Map<String, Object> getDataSourceSubnationalUnitMappings
	(
			@RequestParam(value = "dataSourceId", required = false) Long dataSourceId,
			@RequestParam(value = "rows", required = false) Integer rows,
			@RequestParam(value = "page", required = false) Integer page
	)
	{
		// skip empty request
		
		if (dataSourceId == null)
		{
			Map<String, Object> output = new HashMap<>();
			
			output.put("total", 0);
			output.put("rows", new ArrayList<>());
			
			return output;
			
		}
		
		// get dataSource
		
		DataSource dataSource = getDataSource(dataSourceId);
		
		// get existing subnationalUnitMappings
		
		Map<String, SubnationalUnitMapping> subnationalUnitMappings = new HashMap<>();
		
		for (SubnationalUnitMapping subnationalUnitMapping : dataSource.getSubnationalUnitMappings())
		{
			subnationalUnitMappings.put(subnationalUnitMapping.getRegionColumnValue(), subnationalUnitMapping);
			
		}
		
		Map<String, Long> subnationalUnitValueFrequencies = dataSource.getSubnationalUnitValueFrequencies();
		
		long skip;
		int limit;
		if (rows != null && page != null)
		{
			skip = rows.longValue() * (page.longValue() - 1);
			limit = rows.intValue();
			
		}
		else
		{
			skip = 0L;
			limit = subnationalUnitValueFrequencies.size();
			
		}
		
		// populate output
		
		Map<String, Object> output = new HashMap<>();
		
		output.put("total", subnationalUnitValueFrequencies.size());
		
		List<Map<String, Object>> outputRows = new ArrayList<>();
		output.put("rows", outputRows);
		
		for (String regionColumnValue : subnationalUnitValueFrequencies.keySet().stream().sorted().skip(skip).limit(limit).collect(Collectors.toList()))
		{
			Long regionColumnValueFrequency = subnationalUnitValueFrequencies.get(regionColumnValue);
			
			Map<String, Object> outputRow = new HashMap<>();
			outputRows.add(outputRow);
			
			outputRow.put("subnationalUnitId", (subnationalUnitMappings.containsKey(regionColumnValue) ? subnationalUnitMappings.get(regionColumnValue).getSubnationalUnit().getId() : ""));
			outputRow.put("dataSourceId", dataSource.getId());
			outputRow.put("regionColumnValue", regionColumnValue);
			outputRow.put("regionColumnValueFrequency", regionColumnValueFrequency);
			
		}
		
		return output;
		
	}
	
	@RequestMapping(value = "/setDataSourceSubnationalUnitMapping")
	@Transactional
	@ResponseBody
	public Map<String, Object> setDataSourceSubnationalUnitMapping
	(
			@RequestParam(value = "dataSourceId") Long dataSourceId,
			@RequestParam(value = "regionColumnValue") String regionColumnValue,
			@RequestParam(value = "subnationalUnitId") Long subnationalUnitId
	)
	{
		// get dataSource
		
		Optional<DataSource> optionalDataSource = dataSourceRepository.findById(dataSourceId);
		
		if (!optionalDataSource.isPresent())
		{
			throw new ApplicationException("Cannot find dataSource with id=" + dataSourceId + ".");
			
		}
		
		DataSource dataSource = optionalDataSource.get();
		
		// get subnationalUnitMapping
		
		Optional<SubnationalUnitMapping> optionalSubnationalUnitMapping = subnationalUnitMappingRepository.findByDataSourceIdAndRegionColumnValue(dataSourceId, regionColumnValue);
		
		// delete old mapping
		
		if (optionalSubnationalUnitMapping.isPresent())
		{
			SubnationalUnitMapping subnationalUnitMapping = optionalSubnationalUnitMapping.get();
			
			subnationalUnitMapping.getDataSource().removeSubnationalUnitMapping(subnationalUnitMapping);
			subnationalUnitMapping.getSubnationalUnit().removeSubnationalUnitMapping(subnationalUnitMapping);
			
			subnationalUnitMappingRepository.flush();
			
		}
		
		if (subnationalUnitId != null)
		{
			// get subnationalUnit
			
			Optional<SubnationalUnit> optionalSubnationalUnit = subnationalUnitRepository.findById(subnationalUnitId);
			
			if (!optionalSubnationalUnit.isPresent())
			{
				throw new ApplicationException("Cannot find subnationalUnit with id=" + subnationalUnitId + ".");
				
			}
			
			SubnationalUnit subnationalUnit = optionalSubnationalUnit.get();
			
			// create new mapping
			
			SubnationalUnitMapping subnationalUnitMapping = new SubnationalUnitMapping();
			
			subnationalUnitMapping.setRegionColumnValue(regionColumnValue);
			dataSource.addSubnationalUnitMapping(subnationalUnitMapping);
			subnationalUnit.addSubnationalUnitMapping(subnationalUnitMapping);
				
		}
		
		// return response
		
		return ImmutableMap.of("mapped", isDataSourceAllAggregationLevelsMapped(dataSource));
		
	}
	
	@RequestMapping(value = "/getAllAggregationLevelMapped")
	@ResponseBody
	public Map<String, Object> getAllAggregationLevelMapped
	(
	)
	{
		// get selected ppa
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// return value
		
		boolean allAggregationLevelMapped = true;
		
		// collect used dataSources
		
		Set<DataSource> dataSources = new HashSet<>();
		
		for (Metric metric : selectedPpa.getMetrics())
		{
			// selected metrics only
			
			if (!metric.getSelected())
				continue;
			
			// metric with assigned dataSource only
			
			if (metric.getDataSource() == null)
				continue;
			
			// get dataSource
			
			dataSources.add(metric.getDataSource());
			
		}
		
		for (DataSource dataSource : dataSources)
		{
			// check if all aggregation levels are mapped
			
			Set<String> mappedSubnationalUnits = new HashSet<>();
			for (SubnationalUnitMapping subnationalUnitMapping : dataSource.getSubnationalUnitMappings())
			{
				mappedSubnationalUnits.add(subnationalUnitMapping.getRegionColumnValue());
				
			}
			
			if (!mappedSubnationalUnits.containsAll(dataSource.getSubnationalUnitValueFrequencies().keySet()))
			{
				allAggregationLevelMapped = false;
				
				break;
				
			}
			
		}
		
		// build and return output
		
		return ImmutableMap.of("value", Boolean.valueOf(allAggregationLevelMapped));
		
	}
	
	@RequestMapping(value = "/generateOutput")
	@Transactional
	@ResponseBody
	public void generateOutput
	(
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// run R script

		String outputFileS3Key = getS3Key(s3OutputDirectory, UUID.randomUUID().toString() + EXCEL_OUTPUT_FILE_EXTENSION);
		Map<String, String> chartFileS3Keys = new LinkedHashMap<>();
		
		boolean subnational = !PPA_AGGREGATION_LEVEL_NATIONAL.equals(selectedPpa.getAggregationLevel());
		
		if (subnational)
		{
			for (SubnationalUnit subnationalUnit : selectedPpa.getSubnationalUnits())
			{
				chartFileS3Keys.put(subnationalUnit.getName(), getS3Key(s3OutputDirectory, UUID.randomUUID().toString() + PNG_OUTPUT_FILE_EXTENSION));
				
			}
			
		}
		else
		{
			chartFileS3Keys.put(PPA_AGGREGATION_LEVEL_NATIONAL, getS3Key(s3OutputDirectory, UUID.randomUUID().toString() + PNG_OUTPUT_FILE_EXTENSION));
			
		}
		
		RConnection rConnection = null;
		try
		{
			rConnection = getRserveConnection();
			
			// outputFilePath
			
			rEval(rConnection, String.format("outputFilePath <- \"%s\"", escapeRStringLiteral(getS3MountPathR(outputFileS3Key))));
			
			// chartFilePaths
			
			rEval(rConnection, "chartFilePaths <- list()");
			
			for (Map.Entry<String, String> chartFileS3KeyEntry : chartFileS3Keys.entrySet())
			{
				String subnationalUnit = chartFileS3KeyEntry.getKey();
				String chartFileS3Key = chartFileS3KeyEntry.getValue();
				
				rEval
				(
						rConnection,
						String.format
						(
								"chartFilePaths[[\"%s\"]] <- \"%s\"",
								subnationalUnit,
								escapeRStringLiteral(getS3MountPathR(chartFileS3Key))
						)
				)
				;
				
			}
			
			// ppaName
			
			rEval(rConnection, String.format("PPA.Name <- \"%s\"", selectedPpa.getName()));
			
			// Subnational
			
			rEval(rConnection, String.format("Subnational <- \"%s\"", (subnational ? "TRUE" : "FALSE")));
			
			// Master.Data
			
			List<String> subnationalUnitNames = new ArrayList<>();
			
			if (subnational)
			{
				for (SubnationalUnit subnationalUnit : selectedPpa.getSubnationalUnits())
				{
					subnationalUnitNames.add(subnationalUnit.getName());
					
				}
				
			}
			else
			{
				subnationalUnitNames.add("National");
				
			}
			
			if (subnationalUnitNames.size() == 0)
			{
				throw new ApplicationException("No Subnational Units selected.");
				
			}
			
			Set<PpaSector> ppaSectors = selectedPpa.getPpaSectors();
				
			if (ppaSectors.size() == 0)
			{
				throw new ApplicationException("No PPA Sectors/Levels created.");
				
			}
			
			List<String[]> aggregationValues = new ArrayList<>();
			
			for (String subnationalUnitName : subnationalUnitNames)
			{
				for (PpaSector ppaSector : ppaSectors)
				{
					for (PpaSectorLevel ppaSectorLevel : ppaSector.getPpaSectorLevels())
					{
						aggregationValues.add(new String[] {subnationalUnitName, ppaSector.getName(), String.valueOf(ppaSectorLevel.getLevel()), });
						
					}
					
				}
				
			}
			
			rEval
			(
					rConnection,
					String.format
					(
							"Master.Data <- data.frame(matrix(ncol = %d, nrow = %d))",
							3,
							aggregationValues.size()
					)
			)
			;
			
			rEval(rConnection, "colnames(Master.Data) <- c(\"Subnational\", \"PPA.Sector\", \"PPA.Level\")");
			
			for (int i = 0; i < aggregationValues.size(); i++)
			{
				String[] aggregationValue = aggregationValues.get(i);
				
				rEval
				(
						rConnection,
						String.format
						(
								"Master.Data[%d, \"%s\"] <- \"%s\"",
								i + 1,
								"Subnational",
								aggregationValue[0]
						)
				)
				;
				
				rEval
				(
						rConnection,
						String.format
						(
								"Master.Data[%d, \"%s\"] <- \"%s\"",
								i + 1,
								"PPA.Sector",
								aggregationValue[1]
						)
				)
				;
				
				rEval
				(
						rConnection,
						String.format
						(
								"Master.Data[%d, \"%s\"] <- \"%s\"",
								i + 1,
								"PPA.Level",
								aggregationValue[2]
						)
				)
				;
				
			}
			
			// Metadata
			
			rEval(rConnection, "Metadata <- list()");
			
			for (Metric metric : selectedPpa.getMetrics())
			{
				// selected metrics only
				
				if (!metric.getSelected())
					continue;
				
				// metric with assigned dataSource only
				
				if (metric.getDataSource() == null)
				{
					throw new ApplicationException("Metric " + metric.getDataPointName() + " does not have data source assigned.");
					
				}
				
				// get dataSource
				
				DataSource dataSource = metric.getDataSource();
				
				// variable metadata list
						
				rEval
				(
						rConnection,
						String.format
						(
								"Metadata[[\"%s\"]] <- list()",
								metric.getMetricType().getRName()
						)
				)
				;
				
				// Pathway.Data.Point
				
				rEval
				(
						rConnection,
						String.format
						(
								"Metadata[[\"%s\"]][[\"Pathway.Data.Point\"]] <- \"%s_%s\"",
								metric.getMetricType().getRName(),
								metric.getMetricType().getRHeader(),
								metric.getDataPointName()
						)
				)
				;
				
				rEval
				(
						rConnection,
						String.format
						(
								"Metadata[[\"%s\"]][[\"Pathway.Data.Point.Availability\"]] <- \"%s_%s\"",
								metric.getMetricType().getRName(),
								metric.getMetricType().getRHeaderAvailability(),
								metric.getDataPointName()
						)
				)
				;
				
				rEval
				(
						rConnection,
						String.format
						(
								"Metadata[[\"%s\"]][[\"Pathway.Data.Point.Access\"]] <- \"%s_%s\"",
								metric.getMetricType().getRName(),
								metric.getMetricType().getRHeaderAccess(),
								metric.getDataPointName()
						)
				)
				;
				
				// User.Name.for.Data.Point
				
				rEval
				(
						rConnection,
						String.format
						(
								"Metadata[[\"%s\"]][[\"User.Name.for.Data.Point\"]] <- \"%s\"",
								metric.getMetricType().getRName(),
								metric.getDataPointName()
						)
				)
				;
				
				// Data.Source
				
				rEval
				(
						rConnection,
						String.format
						(
								"Metadata[[\"%s\"]][[\"Data.Source\"]] <- \"%s\"",
								metric.getMetricType().getRName(),
								escapeRStringLiteral(getS3MountPathR(dataSource.getUserFile().getS3FileName()))
						)
				)
				;
				
				// Subset.Columns
				
				rEval
				(
						rConnection,
						String.format
						(
								"Metadata[[\"%s\"]][[\"Subset.Columns\"]] <- list()",
								metric.getMetricType().getRName()
						)
				)
				;
				
				// subset column 1
				
				if (StringUtils.isNotEmpty(dataSource.getSubsetColumn1Name()))
				{
					rEval
					(
							rConnection,
							String.format
							(
									"Metadata[[\"%s\"]][[\"Subset.Columns\"]][[length(Metadata[[\"%s\"]][[\"Subset.Columns\"]]) + 1]] <- list()",
									metric.getMetricType().getRName(),
									metric.getMetricType().getRName()
							)
					)
					;
					
					rEval
					(
							rConnection,
							String.format
							(
									"Metadata[[\"%s\"]][[\"Subset.Columns\"]][[length(Metadata[[\"%s\"]][[\"Subset.Columns\"]])]][[\"Column.Name\"]] <- \"%s\"",
									metric.getMetricType().getRName(),
									metric.getMetricType().getRName(),
									dataSource.getSubsetColumn1Name()
							)
					)
					;
					
					String subsetColumnValues =
							String.format
							(
									"Metadata[[\"%s\"]][[\"Subset.Columns\"]][[length(Metadata[[\"%s\"]][[\"Subset.Columns\"]])]][[\"Column.Values\"]]",
									metric.getMetricType().getRName(),
									metric.getMetricType().getRName()
							)
					;
					
					rPopulateList(rConnection, subsetColumnValues, dataSource.getSubsetColumn1SelectedValues(), true);
					
				}
				
				// subset column 2
				
				if (StringUtils.isNotEmpty(dataSource.getSubsetColumn2Name()))
				{
					rEval
					(
							rConnection,
							String.format
							(
									"Metadata[[\"%s\"]][[\"Subset.Columns\"]][[length(Metadata[[\"%s\"]][[\"Subset.Columns\"]]) + 1]] <- list()",
									metric.getMetricType().getRName(),
									metric.getMetricType().getRName()
							)
					)
					;
					
					rEval
					(
							rConnection,
							String.format
							(
									"Metadata[[\"%s\"]][[\"Subset.Columns\"]][[length(Metadata[[\"%s\"]][[\"Subset.Columns\"]])]][[\"Column.Name\"]] <- \"%s\"",
									metric.getMetricType().getRName(),
									metric.getMetricType().getRName(),
									dataSource.getSubsetColumn2Name()
							)
					)
					;
					
					String subsetColumnValues =
							String.format
							(
									"Metadata[[\"%s\"]][[\"Subset.Columns\"]][[length(Metadata[[\"%s\"]][[\"Subset.Columns\"]])]][[\"Column.Values\"]]",
									metric.getMetricType().getRName(),
									metric.getMetricType().getRName()
							)
					;
					
					rPopulateList(rConnection, subsetColumnValues, dataSource.getSubsetColumn2SelectedValues(), true);
					
				}
				
				// Subnational.Mapping
				
				if (subnational)
				{
					// get subnationalUnitColumName
					
					String subnationalUnitColumName = dataSource.getSubnationalUnitColumnName();
					
					// populate mapping
					
					rEval
					(
							rConnection,
							String.format
							(
									"Metadata[[\"%s\"]][[\"Subnational.Mapping\"]] <- list()",
									metric.getMetricType().getRName()
							)
					)
					;
					
					rEval
					(
							rConnection,
							String.format
							(
									"Metadata[[\"%s\"]][[\"Subnational.Mapping\"]][[\"Column.Name\"]] <- \"%s\"",
									metric.getMetricType().getRName(),
									subnationalUnitColumName
							)
					)
					;
					
					List<SubnationalUnitMapping> subnationalUnitMappings = new ArrayList<>(dataSource.getSubnationalUnitMappings());
					
					rEval
					(
							rConnection,
							String.format
							(
									"Metadata[[\"%s\"]][[\"Subnational.Mapping\"]][[\"Mapping.Table\"]] <- data.frame(matrix(ncol = %d, nrow = %d))",
									metric.getMetricType().getRName(),
									2,
									subnationalUnitMappings.size()
							)
					)
					;
					
					rEval
					(
							rConnection,
							String.format
							(
									"colnames(Metadata[[\"%s\"]][[\"Subnational.Mapping\"]][[\"Mapping.Table\"]]) <- c(\"Data.Source.Value\", \"Subnational\")",
									metric.getMetricType().getRName()
							)
					)
					;
					
					for (int subnationalUnitMappingIndex = 0; subnationalUnitMappingIndex < subnationalUnitMappings.size(); subnationalUnitMappingIndex++)
					{
						SubnationalUnitMapping subnationalUnitMapping = subnationalUnitMappings.get(subnationalUnitMappingIndex);
							
						rEval
						(
								rConnection,
								String.format
								(
										"Metadata[[\"%s\"]][[\"Subnational.Mapping\"]][[\"Mapping.Table\"]][%d, \"%s\"] <- \"%s\"",
										metric.getMetricType().getRName(),
										subnationalUnitMappingIndex + 1,
										"Data.Source.Value",
										subnationalUnitMapping.getRegionColumnValue()
								)
						)
						;
						
						rEval
						(
								rConnection,
								String.format
								(
										"Metadata[[\"%s\"]][[\"Subnational.Mapping\"]][[\"Mapping.Table\"]][%d, \"%s\"] <- \"%s\"",
										metric.getMetricType().getRName(),
										subnationalUnitMappingIndex + 1,
										"Subnational",
										subnationalUnitMapping.getSubnationalUnit().getName()
								)
						)
						;
						
					}
					
				}
				
				// Level.Mapping
				
				// column names
				
				String healthSectorColumnName = dataSource.getHealthSectorColumnName();
				String facilityTypeColumnName = dataSource.getFacilityTypeColumnName();
				
				// collect not empty column names
				
				String[] levelMappingColumnNames;
				
				if (StringUtils.isNotEmpty(facilityTypeColumnName) && StringUtils.isNotEmpty(healthSectorColumnName))
				{
					// check column names are different
					
					if (facilityTypeColumnName.equals(healthSectorColumnName))
					{
						throw new ApplicationException("Incorrect configuration. Data source: " + dataSource.getUserFile().getFileName() + ". Facility Type and Health Sector column names are identical. Either keep just one or make them different.");
						
					}
					
					levelMappingColumnNames = new String[] {healthSectorColumnName, facilityTypeColumnName, };
					
				}
				else if (StringUtils.isNotEmpty(facilityTypeColumnName) && StringUtils.isEmpty(healthSectorColumnName))
				{
					levelMappingColumnNames = new String[] {facilityTypeColumnName, };
					
				}
				else if (StringUtils.isEmpty(facilityTypeColumnName) && StringUtils.isNotEmpty(healthSectorColumnName))
				{
					levelMappingColumnNames = new String[] {healthSectorColumnName, };
					
				}
				else
				{
					throw new ApplicationException("Insufficient configuration. Data source: " + dataSource.getUserFile().getFileName() + ". Either Facility Type or Health Sector column name should be set.");
					
				}
				
				// populate mapping
				
				List<PpaSectorMapping> ppaSectorMappings = new ArrayList<>(dataSource.getPpaSectorMappings());
				
				rEval
				(
						rConnection,
						String.format
						(
								"Metadata[[\"%s\"]][[\"Level.Mapping\"]] <- list()",
								metric.getMetricType().getRName()
						)
				)
				;
				
				rEval
				(
						rConnection,
						String.format
						(
								"Metadata[[\"%s\"]][[\"Level.Mapping\"]][[\"Column.Names\"]] <- c(%s)",
								metric.getMetricType().getRName(),
								StringUtils.join(quoteValues(levelMappingColumnNames), R_LIST_SEPARATOR)
						)
				)
				;
				
				rEval
				(
						rConnection,
						String.format
						(
								"Metadata[[\"%s\"]][[\"Level.Mapping\"]][[\"Mapping.Table\"]] <- data.frame(matrix(ncol = %d, nrow = %d))",
								metric.getMetricType().getRName(),
								2 + levelMappingColumnNames.length,
								ppaSectorMappings.size()
						)
				)
				;
				
				rEval
				(
						rConnection,
						String.format
						(
								"colnames(Metadata[[\"%s\"]][[\"Level.Mapping\"]][[\"Mapping.Table\"]]) <- c(\"PPA.Sector\", \"PPA.Level\", %s)",
								metric.getMetricType().getRName(),
								StringUtils.join(quoteValues(levelMappingColumnNames), R_LIST_SEPARATOR)
						)
				)
				;
				
				for (int ppaSectorMappingIndex = 0; ppaSectorMappingIndex < ppaSectorMappings.size(); ppaSectorMappingIndex++)
				{
					PpaSectorMapping ppaSectorMapping = ppaSectorMappings.get(ppaSectorMappingIndex);
					
					rEval
					(
							rConnection,
							String.format
							(
									"Metadata[[\"%s\"]][[\"Level.Mapping\"]][[\"Mapping.Table\"]][%d, \"PPA.Sector\"] <- \"%s\"",
									metric.getMetricType().getRName(),
									ppaSectorMappingIndex + 1,
									ppaSectorMapping.getPpaSectorLevel().getPpaSector().getName()
							)
					)
					;
					
					rEval
					(
							rConnection,
							String.format
							(
									"Metadata[[\"%s\"]][[\"Level.Mapping\"]][[\"Mapping.Table\"]][%d, \"PPA.Level\"] <- \"%s\"",
									metric.getMetricType().getRName(),
									ppaSectorMappingIndex + 1,
									ppaSectorMapping.getPpaSectorLevel().getLevel()
							)
					)
					;
					
					if (StringUtils.isNotEmpty(healthSectorColumnName))
					{
						rEval
						(
								rConnection,
								String.format
								(
										"Metadata[[\"%s\"]][[\"Level.Mapping\"]][[\"Mapping.Table\"]][%d, \"%s\"] <- \"%s\"",
										metric.getMetricType().getRName(),
										ppaSectorMappingIndex + 1,
										healthSectorColumnName,
										Common.unpackTokens(ppaSectorMapping.getValueCombination())[0]
								)
						)
						;
						
					}
					
					if (StringUtils.isNotEmpty(facilityTypeColumnName))
					{
						rEval
						(
								rConnection,
								String.format
								(
										"Metadata[[\"%s\"]][[\"Level.Mapping\"]][[\"Mapping.Table\"]][%d, \"%s\"] <- \"%s\"",
										metric.getMetricType().getRName(),
										ppaSectorMappingIndex + 1,
										facilityTypeColumnName,
										Common.unpackTokens(ppaSectorMapping.getValueCombination())[1]
								)
						)
						;
						
					}
					
				}
				
				// Weight.Column.Name
				
				if (StringUtils.isNotEmpty(dataSource.getWeightColumnName()))
				{
					rEval
					(
							rConnection,
							String.format
							(
									"Metadata[[\"%s\"]][[\"Weight.Column.Name\"]] <- \"%s\"",
									metric.getMetricType().getRName(),
									dataSource.getWeightColumnName()
							)
					)
					;
					
				}
				
				// Weight.Multiplier
				
				rEval
				(
						rConnection,
						String.format
						(
								"Metadata[[\"%s\"]][[\"Weight.Multiplier\"]] <- %s",
								metric.getMetricType().getRName(),
								dataSource.getWeightMultiplier().toString()
						)
				)
				;
				
				// Count.Values
				
				rEval
				(
						rConnection,
						String.format
						(
								"Metadata[[\"%s\"]][[\"Count.Values\"]] <- list()",
								metric.getMetricType().getRName()
						)
				)
				;
				
				rEval
				(
						rConnection,
						String.format
						(
								"Metadata[[\"%s\"]][[\"Count.Values\"]][[\"Column.Name\"]] <- \"%s\"",
								metric.getMetricType().getRName(),
								metric.getDataSourceColumnName()
						)
				)
				;
				
				String variableColumnValues =
						String.format
						(
								"Metadata[[\"%s\"]][[\"Count.Values\"]][[\"Column.Values\"]]",
								metric.getMetricType().getRName()
						)
				;
				
				rPopulateList(rConnection, variableColumnValues, metric.getSelectedColumnValues(), true);
				
			}
			
			// run the rest of the script
			
			// ensure script exists in Rserve filesystem before sourcing
			String rScriptPathForR = getS3MountPathR(s3RScriptKey);
			REXP scriptExistsRexp = rEval(rConnection, String.format("file.exists(\"%s\")", escapeRStringLiteral(rScriptPathForR)));
			boolean scriptExists;
			try
			{
				scriptExists = ((org.rosuda.REngine.REXPLogical)scriptExistsRexp).asIntegers()[0] == 1;
			}
			catch (Exception e)
			{
				scriptExists = false;
			}
			if (!scriptExists)
			{
				throw new ApplicationException(
						String.format(
								"Missing R script at '%s'.<br/><br/>If Rserve runs in Docker, ensure your host folder is mounted into the container at '%s'.",
								rScriptPathForR,
								s3MountR
						)
				);
			}
			
			rEval(rConnection, String.format("source(\"%s\")", escapeRStringLiteral(rScriptPathForR)));
			
		}
		catch (ApplicationException e)
		{
			// rethrow ApplicationException
			
			throw e;
			
		}
        finally
        {
        	// close RConnection
        	
			if (rConnection != null) rConnection.close();

        }
		
		// update database
		
		Output output = new Output();
		selectedPpa.addOutput(output);
		
		output.setCreated(new Date());
		output.setFileName(outputFileS3Key);
		output.setChartFileNames(chartFileS3Keys);
        
	}
	
	@RequestMapping(value = "/getOutputs")
	@ResponseBody
	public List<Map<String, Object>> getOutputs
	(
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// populate output
		
		List<Map<String, Object>> response = new ArrayList<>();
		
		for (Output output : selectedPpa.getOutputs())
		{
			Map<String, Object> responseRow = new HashMap<>();
			response.add(responseRow);
			
			responseRow.put("id", output.getId());
			
			// Some local installations rely on Hibernate to create the schema and
			// do not have a database default for the 'created' column on the
			// output table. In that case created may be null; avoid NPEs here.
			if (output.getCreated() != null)
			{
				responseRow.put("created", dateFormat.format(output.getCreated()));
			}
			else
			{
				responseRow.put("created", "");
			}
			
			responseRow.put("fileName", output.getFileName());
			responseRow.put("chartNames", output.getChartFileNames().keySet());
			responseRow.put("delete", true);
			
		}
		
		return response;

	}

	@RequestMapping(value = "/deleteOutputs")
	@ResponseBody
	@Transactional
	public void deleteOutputs
	(
			@RequestParam(value = "outputIds[]") List<Long> outputIds
	)
	{
		// get selected PPA
		
		Ppa selectedPpa = getSelectedPpa(true);
		
		// get outputs
		
		List<Output> outputs = outputRepository.findByIdIn(outputIds);
		
		// update database
		
		List<String> outputS3Keys = new ArrayList<>();
		
		for (Output output : outputs)
		{
			outputS3Keys.add(output.getFileName());
			
			selectedPpa.removeOutput(output);
			
		}

		// delete files from storage. In LOCAL_MODE we delete from the shared
		// /s3 mount; in hosted/cloud mode we delete from S3.
		
		if (localMode)
		{
			for (String outputS3Key : outputS3Keys)
			{
				try
				{
					Path localPath = Paths.get(getS3MountPath(outputS3Key));
					Files.deleteIfExists(localPath);
					
				}
				catch (IOException e)
				{
					throw new ApplicationException(e);
					
				}
				
			}
		}
		else
		{
			for (String outputS3Key : outputS3Keys)
			{
				try
				{
					amazonS3.deleteObject(s3Bucket, outputS3Key);
					
				}
				catch (AmazonClientException e)
				{
					throw new ApplicationException(e);
					
				}
				
			}
		}
		
	}

	@RequestMapping(value = "/getOutput")
	@ResponseBody
	public HttpEntity<byte[]> getOutput
	(
			@RequestParam(value = "outputId") Long outputId
	)
	{
		// get ppa
		
		Ppa ppa = getSelectedPpa(true);
		
		// open ZipOutputStream
		
		ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
		ZipOutputStream zipOutputStream = new ZipOutputStream(byteArrayOutputStream);
		
		// get output
		
		Output output = outputRepository.getOne(outputId);
		
		// download output file (S3 first, then local /s3 mount as fallback)
		byte[] outputBytes = readBytesFromS3OrLocal(output.getFileName(), "output Excel file");
		
		// store output file in ZipOutputStream
		
		try
		{
			zipOutputStream.putNextEntry(new ZipEntry(ppa.getName() + ".xlsx"));
			zipOutputStream.write(outputBytes);
			
		}
		catch (IOException e)
		{
			throw new ApplicationException("Cannot create archive.");
			
		}
		
		// process image files
		
		for (Map.Entry<String, String> chartFileNameEntry : output.getChartFileNames().entrySet())
		{
			String chartName = chartFileNameEntry.getKey();
			String chartFileName = chartFileNameEntry.getValue();
			
			try
			{
				// download chart image (S3 first, then local /s3 mount as fallback)
				byte[] imageBytes = readBytesFromS3OrLocal(chartFileName, "output chart file");
				
				// store image file in ZipOutputStream
				zipOutputStream.putNextEntry(new ZipEntry("chart/" + chartName + ".png"));
				zipOutputStream.write(imageBytes);
				
			}
			catch (ApplicationException e)
			{
				// In local/offline mode charts may not be generated; skip missing charts
				System.err.println("Skipping chart '" + chartName + "': " + e.getMessage());
				
			}
			catch (IOException e)
			{
				throw new ApplicationException("Cannot create archive.");
				
			}
			
		}
		
		// close ZipOutputStream
		
		try
		{
			zipOutputStream.close();
			
		}
		catch (IOException e)
		{
			throw new ApplicationException("Cannot create archive.");
			
		}
		
		// get compressed bytes
		
		byte[] compressedBytes = byteArrayOutputStream.toByteArray();
		
		// prepare response
		
		HttpHeaders header = new HttpHeaders();
		header.setContentType(new MediaType("application", "zip"));
		header.set("Content-Disposition", String.format("attachment; filename=%s", ppa.getName() + ".zip"));
		header.setContentLength(compressedBytes.length);

		return new HttpEntity<byte[]>(compressedBytes, header);

	}
	
	@RequestMapping(value = "/getOutputCharts")
	@ResponseBody
	public List<Map<String, Object>> getOutputCharts
	(
			@RequestParam(value = "outputId") Long outputId
	)
	{
		List<Map<String, Object>> response = new ArrayList<>();
		
		// get output
		
		Output output = outputRepository.getOne(outputId);
		
		// process image files
		
		List<Map.Entry<String, String>> chartFileNameEntries = new ArrayList<>(output.getChartFileNames().entrySet());
		Collections.sort(chartFileNameEntries, mapEntryKeyComparator);
		
		for (Map.Entry<String, String> chartFileNameEntry : chartFileNameEntries)
		{
			String subnationalUnit = chartFileNameEntry.getKey();
			String chartFileName = chartFileNameEntry.getValue();
			
			Map<String, Object> responseRow = new HashMap<>();
			response.add(responseRow);
			
			responseRow.put("subnationalUnit", subnationalUnit);
			responseRow.put("chartFileName", chartFileName);
			
		}
		
		return response;

	}

	/**
	 * Simple in-memory MultipartFile implementation backed by a byte array.
	 * Used by the PPA import flow to reuse the existing loadUserFile pipeline.
	 */
	private static class InMemoryMultipartFile implements MultipartFile
	{
		private final String name;
		private final String originalFilename;
		private final String contentType;
		private final byte[] bytes;

		public InMemoryMultipartFile(String name, String originalFilename, String contentType, byte[] bytes)
		{
			this.name = name;
			this.originalFilename = originalFilename;
			this.contentType = contentType;
			this.bytes = (bytes != null ? bytes : new byte[0]);
		}

		@Override
		public String getName()
		{
			return name;
		}

		@Override
		public String getOriginalFilename()
		{
			return originalFilename;
		}

		@Override
		public String getContentType()
		{
			return contentType;
		}

		@Override
		public boolean isEmpty()
		{
			return bytes.length == 0;
		}

		@Override
		public long getSize()
		{
			return bytes.length;
		}

		@Override
		public byte[] getBytes() throws IOException
		{
			return bytes;
		}

		@Override
		public InputStream getInputStream() throws IOException
		{
			return new ByteArrayInputStream(bytes);
		}

		@Override
		public void transferTo(File dest) throws IOException
		{
			Files.write(dest.toPath(), bytes);
		}
	}

	@RequestMapping(value = "/getChartImageBase64String")
	@ResponseBody
	public Map<String, String> getChartImageBase64String
	(
			@RequestParam(value = "chartFileName") String chartFileName
	)
	{
		Map<String, String> response = new HashMap<>();
		
		try
		{
			// download chart image (S3 first, then local /s3 mount as fallback)
			byte[] outputBytes = readBytesFromS3OrLocal(chartFileName, "output chart file");
			String chartImageBase64String = Base64.getEncoder().encodeToString(outputBytes);
			response.put("chartImageBase64String", chartImageBase64String);
			
		}
		catch (ApplicationException e)
		{
			// In local/offline mode charts may not exist; return empty string instead of failing hard
			System.err.println("Cannot load chart image '" + chartFileName + "': " + e.getMessage());
			response.put("chartImageBase64String", "");
			
		}
		
		return response;

	}
	
	@RequestMapping(value = "/confirmEmail")
	@PreAuthorize("permitAll()")
	@Transactional
	public void confirmEmail
	(
			@RequestParam(value = "token", required = false) String token
	)
	{
		// get user by token
		
		User user = userRepository.findByRegisterUserToken(token);
		
		if (user == null)
		{
			throw new ApplicationException(getMessageText("confirmEmail.invalidConfirmation.message", new String[] {}));
			
		}
		
		if (new Duration(user.getRegisterUserTokenCreated(), DateTime.now()).getStandardSeconds() > tokenTimeoutSeconds)
		{
			throw new ApplicationException(getMessageText("confirmEmail.expiredConfirmation.message", new String[] {}));
			
		}
		
		user.setEnabled(true);
		user.setRegisterUserToken(null);
		user.setRegisterUserTokenCreated(null);
		
	}
	
	@RequestMapping(value = "/sendConfirmation")
	@PreAuthorize("permitAll()")
	@Transactional
	public void sendConfirmation
	(
			@RequestParam(value = "email") String email
	)
	{
		// get user by email
		
		User user = userRepository.findByEmail(email);
		
		if (user == null)
		{
			throw new ApplicationException(getMessageText("sendConfirmation.userNotFound.message", new String[] {}));
			
		}
		
		// send confirmation email
		
		sendConfirmationEmail(user);
		
	}
	
	@RequestMapping(value = "/getAcceptInvitationTokenVerification")
	@PreAuthorize("permitAll()")
	@ResponseBody
	public Map<String, Object> getAcceptInvitationTokenVerification
	(
			@RequestParam(value = "token", required = false) String token
	)
	{
		Map<String, Object> response = new HashMap<>();
		
		// get invitation by token
		
		Invitation invitation = getTokenInvitation(token);
		
		response.put("invitationAccountName", invitation.getAccount().getName());
		response.put("invitationExistingUser", userRepository.existsByUsername(invitation.getEmail()));
		
		return response;
		
	}
	
	@RequestMapping(value = "/getResetPasswordTokenVerification")
	@PreAuthorize("permitAll()")
	@ResponseBody
	public Map<String, Object> getResetPasswordTokenVerification
	(
			@RequestParam(value = "token") String token
	)
	{
		Map<String, Object> response = new HashMap<>();
		
		// get invitation with token
		
		List<User> users = userRepository.findByResetPasswordToken(token);
		
		// check token
		
		if (users.size() == 1)
		{
			User user = users.get(0);
			
			if (new Duration(user.getResetPasswordTokenCreated(), DateTime.now()).getStandardSeconds() < tokenTimeoutSeconds)
			{
				response.put("success", true);
				response.put("username", user.getUsername());
				
			}
			else
			{
				response.put("success", false);
				response.put("error", "expired");
				
			}
			
		}
		else
		{
			response.put("success", false);
			response.put("error", "invalid");
			
		}
		
		return response;
		
	}
	
	@RequestMapping(value = "/getMaxInactiveInterval")
	@PreAuthorize("permitAll()")
	@ResponseBody
	public Map<String, Object> getMaxInactiveInterval
	(
			HttpServletRequest httpServletRequest
	)
	{
		return ImmutableMap.of("maxInactiveInterval", httpServletRequest.getSession().getMaxInactiveInterval());
		
	}
	
}

