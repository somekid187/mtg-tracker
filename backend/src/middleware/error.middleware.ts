import status from "../config/status.config.json";
import appError from "../config/error.config.json";

export default function errorHandler(err: any, req: any, res: any, next: any) {
  // Log error, server-side only
  console.error("Error:", {
    code: err.code,
    message: err.message,
    stack: err.stack,
  });

  // If headers are already sent, delegate to default Express error handler
  if (res.headersSent) {
    return next(err);
  }

  // Handle known error types
  if (err.code) {
    const errorConfig = appError[err.code as keyof typeof appError];
    if (errorConfig) {
      const statusCode = errorConfig.code || 500;
      console.log(`Handling error ${err.code} with status code ${statusCode}`);
      return res.status(statusCode).json({
        success: false,
        data: null,
        error: { message: err.message || "An error occurred", code: err.code, status: statusCode },
      });
    }
  }

  // Handle validation
    if (err.name === "ValidationError") {
        return res.status(status.BAD_REQUEST.code).json({
            success: false,
            data: null,
            error: { message: err.message || "Validation Error", code: "VALIDATION_ERROR", status: status.BAD_REQUEST.code }
        });
    } else if (err.name === "SyntaxError" && err.status === 400 && "body" in err) {
        return res.status(status.BAD_REQUEST.code).json({
            success: false,
            data: null,
            error: { message: "Invalid JSON payload", code: "INVALID_JSON", status: status.BAD_REQUEST.code }
        });
    }
    
    // Default error response
  return res.status(status.INTERNAL_ERROR.code).json({
    success: false,
    data: null,
    error: { message: "Internal Server Error", code: "INTERNAL_SERVER_ERROR", status: status.INTERNAL_ERROR.code }
  });
}
