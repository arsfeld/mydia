defmodule Mydia.CrashReporter.SanitizerTest do
  use ExUnit.Case, async: true

  alias Mydia.CrashReporter.Sanitizer

  describe "sanitize/1" do
    test "sanitizes usernames in file paths" do
      report = %{
        error_message: "File not found: /home/user/mydia/data/file.txt"
      }

      result = Sanitizer.sanitize(report)

      assert result.error_message == "File not found: /home/[USER]/mydia/data/file.txt"
    end

    test "sanitizes usernames in Windows file paths" do
      report = %{
        error_message: "Access denied: C:\\Users\\john\\Documents\\file.txt"
      }

      result = Sanitizer.sanitize(report)

      assert result.error_message == "Access denied: C:\\Users\\[USER]\\Documents\\file.txt"
    end

    test "sanitizes usernames in stacktrace file paths" do
      report = %{
        stacktrace: [
          %{file: "/home/user/mydia/lib/mydia/app.ex", line: 42, function: "run/1"},
          %{file: "/home/user/mydia/lib/mydia/web/router.ex", line: 15, function: "call/2"}
        ]
      }

      result = Sanitizer.sanitize(report)

      assert [entry1, entry2] = result.stacktrace
      assert entry1.file == "/home/[USER]/mydia/lib/mydia/app.ex"
      assert entry1.line == 42
      assert entry2.file == "/home/[USER]/mydia/lib/mydia/web/router.ex"
      assert entry2.line == 15
    end

    test "keeps paths without usernames unchanged" do
      report = %{
        error_message: "Error in /app/lib/mydia/app.ex:42",
        stacktrace: [
          %{file: "/app/lib/mydia/app.ex", line: 42}
        ]
      }

      result = Sanitizer.sanitize(report)

      assert result.error_message == "Error in /app/lib/mydia/app.ex:42"
      assert hd(result.stacktrace).file == "/app/lib/mydia/app.ex"
    end

    test "redacts API keys in error messages" do
      report = %{
        error_message: "API key abc123def456ghi789jkl012mno345pqr is invalid"
      }

      result = Sanitizer.sanitize(report)

      assert result.error_message == "API key [REDACTED] is invalid"
    end

    test "redacts bearer tokens" do
      report = %{
        error_message: "Authentication failed with Bearer abc123def456ghi789"
      }

      result = Sanitizer.sanitize(report)

      assert result.error_message == "Authentication failed with Bearer [REDACTED]"
    end

    test "redacts JWT tokens" do
      report = %{
        error_message:
          "Invalid token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U"
      }

      result = Sanitizer.sanitize(report)

      assert result.error_message == "Invalid token: [REDACTED]"
    end

    test "redacts passwords in error messages" do
      report = %{
        error_message: "Database connection failed: password: secret123"
      }

      result = Sanitizer.sanitize(report)

      assert result.error_message == "Database connection failed: password: [REDACTED]"
    end

    test "redacts URLs with credentials" do
      report = %{
        error_message: "Failed to connect to https://user:pass123@example.com/api"
      }

      result = Sanitizer.sanitize(report)

      assert result.error_message ==
               "Failed to connect to https://[REDACTED]:[REDACTED]@example.com/api"
    end

    test "redacts database connection strings" do
      report = %{
        error_message: "Connection failed: postgres://user:password@localhost/db"
      }

      result = Sanitizer.sanitize(report)

      assert result.error_message ==
               "Connection failed: postgres://[REDACTED]:[REDACTED]@localhost/db"
    end

    test "keeps IP addresses for debugging" do
      report = %{
        error_message: "Connection from 192.168.1.100 denied"
      }

      result = Sanitizer.sanitize(report)

      # IP addresses are kept for debugging network issues
      assert result.error_message == "Connection from 192.168.1.100 denied"
    end

    test "redacts sensitive metadata keys" do
      report = %{
        metadata: %{
          "api_key" => "secret123",
          "password" => "pass456",
          "secret_token" => "token789",
          "normal_value" => "ok"
        }
      }

      result = Sanitizer.sanitize(report)

      assert result.metadata == %{
               "api_key" => "[REDACTED]",
               "password" => "[REDACTED]",
               "secret_token" => "[REDACTED]",
               "normal_value" => "ok"
             }
    end

    test "sanitizes nested metadata" do
      report = %{
        metadata: %{
          "user" => %{
            "name" => "John",
            "email" => "john@example.com",
            "api_key" => "secret123"
          }
        }
      }

      result = Sanitizer.sanitize(report)

      assert result.metadata == %{
               "user" => %{
                 "name" => "John",
                 "email" => "john@example.com",
                 "api_key" => "[REDACTED]"
               }
             }
    end

    test "sanitizes metadata lists" do
      report = %{
        metadata: %{
          "credentials" => [
            %{"username" => "user1", "password" => "pass1"},
            %{"username" => "user2", "password" => "pass2"}
          ]
        }
      }

      result = Sanitizer.sanitize(report)

      assert result.metadata == %{
               "credentials" => [
                 %{"username" => "user1", "password" => "[REDACTED]"},
                 %{"username" => "user2", "password" => "[REDACTED]"}
               ]
             }
    end

    test "handles nil values gracefully" do
      report = %{
        error_message: nil,
        stacktrace: nil,
        metadata: nil
      }

      result = Sanitizer.sanitize(report)

      assert result == %{
               error_message: nil,
               stacktrace: nil,
               metadata: nil
             }
    end

    test "handles empty collections" do
      report = %{
        error_message: "",
        stacktrace: [],
        metadata: %{}
      }

      result = Sanitizer.sanitize(report)

      assert result == %{
               error_message: "",
               stacktrace: [],
               metadata: %{}
             }
    end

    test "comprehensive sanitization example" do
      report = %{
        error_message:
          "Database connection failed at /home/user/mydia/lib/mydia/repo.ex with postgres://admin:secret@192.168.1.10/mydb",
        stacktrace: [
          %{
            file: "/home/user/mydia/lib/mydia/repo.ex",
            line: 42,
            module: "Mydia.Repo",
            function: "connect/1"
          },
          %{
            file: "/home/user/mydia/lib/mydia/application.ex",
            line: 15,
            module: "Mydia.Application",
            function: "start/2"
          }
        ],
        metadata: %{
          "database_url" => "postgres://admin:secret@localhost/mydb",
          "api_key" => "abcdef123456",
          "user_email" => "admin@example.com",
          "server_ip" => "192.168.1.10",
          "version" => "1.0.0"
        }
      }

      result = Sanitizer.sanitize(report)

      # Check error message sanitization - username redacted but path kept
      assert result.error_message =~
               "/home/[USER]/mydia/lib/mydia/repo.ex with postgres://[REDACTED]:[REDACTED]@192.168.1.10/mydb"

      # Check stacktrace sanitization - username redacted but path kept
      assert [entry1, entry2] = result.stacktrace
      assert entry1.file == "/home/[USER]/mydia/lib/mydia/repo.ex"
      assert entry2.file == "/home/[USER]/mydia/lib/mydia/application.ex"

      # Check metadata sanitization - only secrets redacted
      assert result.metadata["database_url"] =~
               "postgres://[REDACTED]:[REDACTED]@localhost/mydb"

      assert result.metadata["api_key"] == "[REDACTED]"
      # Emails and IPs are kept for debugging
      assert result.metadata["user_email"] == "admin@example.com"
      assert result.metadata["server_ip"] == "192.168.1.10"
      assert result.metadata["version"] == "1.0.0"
    end
  end
end
