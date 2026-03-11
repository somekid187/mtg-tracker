import status from "../config/status.config.json";
import appError from "../config/error.config.json";

export default function errorHandler(err: any, req: any, res: any, next: any) {
  // Log the full error object to see what we're dealing with
  console.error("Full error object:", err);
  console.error("Error type:", typeof err);
  console.error("Error constructor:", err?.constructor?.name);
  
  // Log error, server-side only
  console.error("Error:", {
    code: err.code,
    message: err.message,
    stack: err.stack,
    status: err.status || 500,
    errno: err.errno,
    sqlMessage: err.sqlMessage,
    sqlState: err.sqlState,
  });

  // If headers are already sent, delegate to default Express error handler
  if (res.headersSent) {
    return next(err);
  }

  // Handle MySQL/Database errors
  if (err.code && (err.errno || err.sqlMessage)) {
    return res.status(500).json({
      success: false,
      data: null,
      error: { 
        message: err.sqlMessage || err.message || "Database error", 
        code: "DATABASE_ERROR" 
      },
    });
  }

  // Handle known error types
  if (err.code) {
    const errorConfig = appError[err.code as keyof typeof appError];
    if (errorConfig) {
      return res.status(errorConfig.code).json({
        success: false,
        data: null,
        error: { message: err.message || "An error occurred", code: err.code },
      });
    }
  }

  // Handle validation
    if (err.name === "ValidationError") {
        return res.status(status.BAD_REQUEST.code).json({
            success: false,
            data: null,
            error: { message: err.message || "Validation Error", code: "VALIDATION_ERROR" }
        });
    } else if (err.name === "SyntaxError" && err.status === 400 && "body" in err) {
        return res.status(status.BAD_REQUEST.code).json({
            success: false,
            data: null,
            error: { message: "Invalid JSON payload", code: "INVALID_JSON" }
        });
    }

  // Default error response
  return res.status(status.INTERNAL_ERROR.code).json({
    success: false,
    data: null,
    error: { message: "Internal Server Error", code: "INTERNAL_SERVER_ERROR" }
  });
}
