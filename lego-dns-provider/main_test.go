package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"strings"
	"testing"

	"github.com/go-acme/lego/v5/log"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
)

type LogHandler struct {
	mock.Mock
}

func (l *LogHandler) Enabled(ctx context.Context, level slog.Level) bool {
	return true
}

func (l *LogHandler) Handle(ctx context.Context, record slog.Record) error {
	l.Called(ctx, record)

	return nil
}

func (l *LogHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	panic("implement me")
}

func (l *LogHandler) WithGroup(name string) slog.Handler {
	panic("implement me")
}

// based on go-acme/lego/providers/dns/exec/exec_test.go
func TestRunProvider(t *testing.T) {
	backupLogger := log.Default()

	defer func() {
		log.SetDefault(backupLogger)
	}()

	logHandler := &LogHandler{}
	log.SetDefault(slog.New(logHandler))

	type expected struct {
		args  string
		error bool
	}

	testCases := []struct {
		desc     string
		args     []string
		expected expected
	}{
		{
			desc: "Simple present",
			args: []string{"present", "your-domain.example.", "token", "Iu5cheer"},
			expected: expected{
				args: "present _acme-challenge.your-domain.example. 5oUOMvfJy448xr3AEkDttrV7dU4vjobaH_K3XUvwH7Q",
			},
		},
		{
			desc: "Simple cleanup",
			args: []string{"cleanup", "your-domain.example.", "token", "Iu5cheer"},
			expected: expected{
				args: "cleanup _acme-challenge.your-domain.example. 5oUOMvfJy448xr3AEkDttrV7dU4vjobaH_K3XUvwH7Q",
			},
		},
		{
			desc: "No trailing '.'",
			args: []string{"present", "your-domain.example", "token", "Iu5cheer"},
			expected: expected{
				args: "present _acme-challenge.your-domain.example. 5oUOMvfJy448xr3AEkDttrV7dU4vjobaH_K3XUvwH7Q",
			},
		},
	}

	var message string

	logHandler.On("Handle", mock.Anything, mock.Anything).Run(func(args mock.Arguments) {
		message = args.Get(1).(slog.Record).Message
		fmt.Fprintln(os.Stdout, "XXX", message)
	})

	for _, test := range testCases {
		t.Run(test.desc, func(t *testing.T) {
			message = ""

			os.Setenv("EXEC_PATH", "echo")

			err := runProvider("exec", test.args[0], test.args[1], test.args[2], test.args[3])

			if test.expected.error {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
				assert.Equal(t, test.expected.args, strings.TrimSpace(message))
			}
		})
	}
}

func TestBadProvider(t *testing.T) {
	err := runProvider("no-such-provider", "present", "your-domain.example.", "token", "Iu5cheer")

	require.ErrorContains(t, err, "unrecognized DNS provider")
}

func TestBadOperation(t *testing.T) {
	err := runProvider("exec", "no-such-operation", "your-domain.example.", "token", "Iu5cheer")

	require.ErrorContains(t, err, "unrecognized operation")
}
