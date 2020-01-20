package main

import (
	"database/sql"
	"flag"
	"fmt"
	"os"
	"strconv"
	"sync"
	"time"

	"github.com/fatih/color"
	_ "github.com/lib/pq"
)

var (
	inittime = time.Now()
	password = flag.String("password", "", "Password to use")
	host     = flag.String("host", "123.123.123.123", "IP or FQDN of host connect to")
	port     = flag.Int("port", 5432, "Port of server")
	user     = flag.String("user", "postgres", "User to login as")
	database = flag.String("database", "", "Database to attempt connection to")
	attempts = flag.Int("attempts", 3, "Amount of times to attempt login")
	timer    = flag.Duration("timer", 300*time.Millisecond, "Timeout between attempts")
)

type resp struct {
	Error error
	mu    sync.Mutex
}

// PostgreSQLConnect will attemt to connect to the specified database on the remote host
func PostgreSQLConnect(user, password, host, database string, port int) *resp {
	exitcode := &resp{}
	var psqlInfo string

	// If password is empty, do not include it at all as that may cause issues
	if password == "" {
		psqlInfo = fmt.Sprintf("host=%s port=%d user=%s "+
			"dbname=%s sslmode=disable",
			host, port, user, database)
	} else {
		psqlInfo = fmt.Sprintf("host=%s port=%d user=%s "+
			"password=%s dbname=%s sslmode=disable",
			host, port, user, password, database)
	}

	db, err := sql.Open("postgres", psqlInfo)
	if err != nil {
		fmt.Printf("Connection failed. Error: \n%s\n", err)
	}
	defer db.Close()

	if err = db.Ping(); err == nil {
		end := time.Now()
		d := end.Sub(inittime)
		duration := d.Seconds()
		fmt.Fprintf(color.Output, "\n%s", color.YellowString("###########################"))
		fmt.Fprintf(color.Output, "\n%s", color.GreenString("Successful connection"))
		fmt.Fprintf(color.Output, "\n%s", color.YellowString("###########################"))
		fmt.Printf("\nCompleted in %v seconds\n", strconv.FormatFloat(duration, 'g', -1, 64))
	} else {
		fmt.Printf("Connection failed. Error:\n%s\n", err)
	}

	exitcode.Error = err
	return exitcode
}

func main() {
	flag.Parse()

	for attempt := *attempts; attempt != 0; attempt-- {
		go func() {
			resp := PostgreSQLConnect(*user, *password, *host, *database, *port)
			resp.mu.Lock()
			if resp.Error == nil {
				resp.mu.Unlock()
				os.Exit(0)
			}
		}()

		fmt.Println("Attempts left: ", attempt)
		time.Sleep(*timer)
	}
}
