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

	var message string

	logHandler.On("Handle", mock.Anything, mock.Anything).Run(func(args mock.Arguments) {
		message = args.Get(1).(slog.Record).Message
		fmt.Fprintln(os.Stdout, "XXX", message)
	})

	message = ""

	os.Setenv("EXEC_PATH", "echo")
	err := runProvider("exec", "present", "your-domain.example.", "token", "Iu5cheer")

	require.NoError(t, err)
	assert.Equal(t, "present _acme-challenge.your-domain.example. 5oUOMvfJy448xr3AEkDttrV7dU4vjobaH_K3XUvwH7Q", strings.TrimSpace(message))
}
